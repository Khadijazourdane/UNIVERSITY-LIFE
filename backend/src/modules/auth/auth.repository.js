// L’adaptateur lit les champs officiels d’utilisateur et renvoie null en cas d’absence.
// updatePassword({ userId, expectedHash, newHash }) renvoie true uniquement si
// la mise à jour est effectuée atomiquement avec le hash attendu.
export function requireAuthRepository(repository) {
  for (const method of ['findByEmail', 'findById', 'updatePassword']) {
    if (typeof repository?.[method] !== 'function') {
      throw new TypeError(`Le dépôt Auth doit fournir ${method}().`);
    }
  }
  return repository;
}

export class AuthRepositoryUnavailableError extends Error {}

const userFields = 'id_utilisateur, nom, prenom, email, mot_de_passe, role';

export function createPostgresAuthRepository(pool) {
  async function query(text, values) {
    try {
      return await pool.query(text, values);
    } catch {
      throw new AuthRepositoryUnavailableError('Le stockage PostgreSQL Auth est indisponible.');
    }
  }

  return {
    async findByEmail(email) {
      const result = await query(`SELECT ${userFields} FROM public.utilisateur WHERE email = $1`, [email]);
      return result.rows[0] ?? null;
    },
    async findById(userId) {
      const result = await query(`SELECT ${userFields} FROM public.utilisateur WHERE id_utilisateur = $1`, [userId]);
      return result.rows[0] ?? null;
    },
    async updatePassword({ userId, expectedHash, newHash }) {
      const result = await query(
        'UPDATE public.utilisateur SET mot_de_passe = $3 WHERE id_utilisateur = $1 AND mot_de_passe = $2',
        [userId, expectedHash, newHash],
      );
      return result.rowCount === 1;
    },
  };
}
