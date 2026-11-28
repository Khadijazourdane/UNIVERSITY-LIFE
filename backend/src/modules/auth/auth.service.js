import { AuthError } from '../../middleware/error-handler.js';
import { AuthRepositoryUnavailableError, requireAuthRepository } from './auth.repository.js';
import { fingerprint } from './auth.session-store.js';
import { isAuthRole, validateLogin, validatePasswordChange } from './auth.validation.js';

function publicUser({ id_utilisateur, nom, prenom, email, role }) {
  return { id_utilisateur, nom, prenom, email, role };
}

async function runRepository(operation) {
  try {
    return await operation();
  } catch (error) {
    if (error instanceof AuthRepositoryUnavailableError) {
      throw new AuthError('AUTH_UNAVAILABLE');
    }
    throw error;
  }
}

export function createAuthService({ repository, passwords, sessions }) {
  requireAuthRepository(repository);

  async function login(input, previousToken) {
    const { email, password } = validateLogin(input);
    const account = await runRepository(() => repository.findByEmail(email));
    const verified = await passwords.verify(password, account?.mot_de_passe);
    if (!account || !verified || !isAuthRole(account.role)) {
      throw new AuthError('INVALID_CREDENTIALS');
    }

    const latest = await runRepository(() => repository.findById(account.id_utilisateur));
    if (!latest || latest.role !== account.role || latest.mot_de_passe !== account.mot_de_passe) {
      throw new AuthError('INVALID_CREDENTIALS');
    }

    const issued = sessions.issue({
      userId: latest.id_utilisateur,
      role: latest.role,
      passwordFingerprint: fingerprint(latest.mot_de_passe),
    }, previousToken);

    return { user: publicUser(latest), ...issued };
  }

  async function resolveSession(token) {
    const session = sessions.get(token);
    if (!session) {
      throw new AuthError('SESSION_INVALID');
    }

    const account = await runRepository(() => repository.findById(session.userId));
    if (sessions.get(token) !== session) {
      throw new AuthError('SESSION_INVALID');
    }
    if (!account || !isAuthRole(account.role) || account.role !== session.role
        || fingerprint(account.mot_de_passe) !== session.passwordFingerprint) {
      sessions.revoke(token);
      throw new AuthError('SESSION_INVALID');
    }

    return { account, session };
  }

  async function me(token) {
    const { account, session } = await resolveSession(token);
    return { user: publicUser(account), expiresAt: session.expiresAt };
  }

  async function changePassword(token, input) {
    const { currentPassword, newPassword } = validatePasswordChange(input);
    const { account, session } = await resolveSession(token);
    const valid = await passwords.verify(currentPassword, account.mot_de_passe);
    if (!valid) {
      throw new AuthError('CURRENT_PASSWORD_INVALID');
    }

    const newHash = await passwords.hash(newPassword);
    if (sessions.get(token) !== session) {
      throw new AuthError('SESSION_INVALID');
    }

    const updated = await runRepository(() => repository.updatePassword({
      userId: account.id_utilisateur,
      expectedHash: account.mot_de_passe,
      newHash,
    }));
    if (!updated) {
      throw new AuthError('PASSWORD_UPDATE_CONFLICT');
    }

    sessions.revokeUser(account.id_utilisateur);
  }

  function logout(token) {
    sessions.revoke(token);
  }

  return { login, me, changePassword, logout };
}
