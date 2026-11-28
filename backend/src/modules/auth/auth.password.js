import { randomBytes } from 'node:crypto';
import argon2 from 'argon2';

import { hasPasswordLength } from './auth.validation.js';

const options = Object.freeze({
  type: argon2.argon2id,
  version: 0x13,
  memoryCost: 19 * 1024,
  timeCost: 2,
  parallelism: 1,
  hashLength: 32,
});
const compatibleHash = /^\$argon2id\$v=19\$m=19456,t=2,p=1\$[A-Za-z0-9+/]{22}\$[A-Za-z0-9+/]{43}$/;

// Le vérificateur et le hash factice doivent utiliser un format et un coût comparables.
export function createPasswordService({ hash, verify, dummyHash }) {
  if (typeof hash !== 'function' || typeof verify !== 'function'
      || typeof dummyHash !== 'string' || !dummyHash) {
    throw new TypeError('La stratégie de mots de passe doit fournir hash, verify et dummyHash.');
  }

  return {
    hash,
    verify: (password, storedHash) => verify(password, storedHash ?? dummyHash),
  };
}

export async function createArgon2PasswordService() {
  const dummyHash = await argon2.hash(randomBytes(32), options);
  return createPasswordService({
    dummyHash,
    async hash(password) {
      if (!hasPasswordLength(password, 8)) {
        throw new RangeError('Un mot de passe doit compter entre 8 et 256 caractères Unicode.');
      }
      return argon2.hash(password, options);
    },
    async verify(password, storedHash) {
      if (!hasPasswordLength(password)) return false;
      if (typeof storedHash !== 'string' || !compatibleHash.test(storedHash)) {
        await argon2.verify(dummyHash, password);
        return false;
      }
      return argon2.verify(storedHash, password);
    },
  });
}
