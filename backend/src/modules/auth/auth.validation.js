import { AuthError } from '../../middleware/error-handler.js';

const roles = new Set(['etudiant', 'professeur', 'admin']);
const academicEmail = /^[^@\s\u0000-\u001f\u007f]+@edu\.uiz\.ac\.ma$/i;
export const MAX_PASSWORD_LENGTH = 256;

export function hasPasswordLength(password, minimum = 1) {
  if (typeof password !== 'string' || password.length > 2 * MAX_PASSWORD_LENGTH) return false;
  const length = [...password].length;
  return length >= minimum && length <= MAX_PASSWORD_LENGTH;
}

export function isAuthRole(role) {
  return roles.has(role);
}

function readStrings(body, fields) {
  if (body === null || typeof body !== 'object' || Array.isArray(body)
      || Object.keys(body).length !== fields.length
      || fields.some((field) => !Object.hasOwn(body, field)
        || typeof body[field] !== 'string' || body[field].length === 0)) {
    throw new AuthError('INVALID_REQUEST');
  }
  return body;
}

export function validateLogin(body) {
  const { email: address, password } = readStrings(body, ['email', 'password']);
  const email = normalizeAcademicEmail(address);
  if (!hasPasswordLength(password)) {
    throw new AuthError('INVALID_REQUEST');
  }
  return { email, password };
}

export function normalizeAcademicEmail(address) {
  if (typeof address !== 'string') throw new AuthError('INVALID_REQUEST');
  const email = address.trim().toLowerCase();
  if ([...email].length > 100 || !academicEmail.test(email)) {
    throw new AuthError('INVALID_REQUEST');
  }
  return email;
}

export function validatePasswordChange(body) {
  const { currentPassword, newPassword } = readStrings(body, ['currentPassword', 'newPassword']);
  if (!hasPasswordLength(currentPassword)) {
    throw new AuthError('INVALID_REQUEST');
  }
  if (!hasPasswordLength(newPassword, 8) || newPassword === currentPassword) {
    throw new AuthError('PASSWORD_POLICY');
  }
  return { currentPassword, newPassword };
}
