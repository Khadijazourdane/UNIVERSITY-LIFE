export const TEST_DATABASE = 'university_life_auth_test';
export const TEST_ROLE = 'university_life_auth_test_app';
export const AUTH_ROLES = ['etudiant', 'professeur', 'admin'];

export function isLocalPostgres(config) {
  return ['localhost', '127.0.0.1', '::1'].includes(config?.host);
}

export function fixtureAccounts(env) {
  return AUTH_ROLES.map((role, index) => {
    const key = `AUTH_TEST_${role.toUpperCase()}`;
    const email = env[`${key}_EMAIL`];
    const password = env[`${key}_PASSWORD`];
    if (!email || !password) throw new Error('Les comptes de test doivent être renseignés dans .env.auth-test.');
    return { id: index + 1, role, email, password };
  });
}
