const { query, getClient } = require('../config/database');

class Documento {
  /**
   * Crear un nuevo documento
   */
  static async create(documentoData) {
    const {
      codigo,
      nombre,
      descripcion,
      gestion_id,
      convencion,
      archivo_fuente,
      archivo_pdf,
      usuario_creador
    } = documentoData;

    const sql = `
      INSERT INTO documentos (
        codigo, nombre, descripcion, gestion_id, convencion, 
        archivo_fuente, archivo_pdf, usuario_creador,
        version, estado
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 1, 'pendiente_aprobacion')
      RETURNING *
    `;

    const values = [
      codigo, nombre, descripcion, gestion_id, convencion,
      archivo_fuente, archivo_pdf, usuario_creador
    ];

    const result = await query(sql, values);
    return result.rows[0];
  }

  /**
   * Obtener documento por ID
   */
  static async findById(id) {
    const sql = `
      SELECT d.*, 
             g.nombre as gestion_nombre,
             uc.name as creador_nombre,
             ur.name as revisor_nombre,
             ua.name as aprobador_nombre
      FROM documentos d
      LEFT JOIN gestiones g ON d.gestion_id = g.id
      LEFT JOIN users uc ON d.usuario_creador = uc.id
      LEFT JOIN users ur ON d.usuario_revisor = ur.id
      LEFT JOIN users ua ON d.usuario_aprobador = ua.id
      WHERE d.id = $1
    `;

    const result = await query(sql, [id]);
    return result.rows[0];
  }

  /**
   * Obtener todos los documentos con filtros opcionales
   */
  static async findAll(filters = {}) {
    let sql = `
      SELECT d.*, 
             g.nombre as gestion_nombre,
             uc.name   as creador_nombre,
             ur.name as revisor_nombre,
             ua.name as aprobador_nombre
      FROM documentos d
      LEFT JOIN gestiones g ON d.gestion_id = g.id
      LEFT JOIN users uc ON d.usuario_creador = uc.id
      LEFT JOIN users ur ON d.usuario_revisor = ur.id
      LEFT JOIN users ua ON d.usuario_aprobador = ua.id
      WHERE 1=1
    `;

    const values = [];
    let paramCount = 0;

    // Aplicar filtros
    if (filters.codigo) {
      paramCount++;
      sql += ` AND d.codigo ILIKE $${paramCount}`;
      values.push(`%${filters.codigo}%`);
    }

    if (filters.nombre) {
      paramCount++;
      sql += ` AND d.nombre ILIKE $${paramCount}`;
      values.push(`%${filters.nombre}%`);
    }

    if (filters.gestion_id) {
      paramCount++;
      sql += ` AND d.gestion_id = $${paramCount}`;
      values.push(filters.gestion_id);
    }

    if (filters.convencion) {
      paramCount++;
      sql += ` AND d.convencion = $${paramCount}`;
      values.push(filters.convencion);
    }

    if (filters.estado) {
      paramCount++;
      sql += ` AND d.estado = $${paramCount}`;
      values.push(filters.estado);
    }

    // Ordenamiento
    sql += ` ORDER BY d.fecha_creacion DESC`;

    // Paginación
    if (filters.limit) {
      paramCount++;
      sql += ` LIMIT $${paramCount}`;
      values.push(parseInt(filters.limit));
    }

    if (filters.offset) {
      paramCount++;
      sql += ` OFFSET $${paramCount}`;
      values.push(parseInt(filters.offset));
    }

    const result = await query(sql, values);
    return result.rows;
  }

  /**
   * Actualizar documento (incrementa versión y guarda histórico)
   */
  static async update(id, updateData, usuario_id) {
    const client = await getClient();
    
    try {
      await client.query('BEGIN');

      // Obtener documento actual
      const currentDoc = await client.query('SELECT * FROM documentos WHERE id = $1', [id]);
      if (currentDoc.rows.length === 0) {
        throw new Error('Documento no encontrado');
      }

      const current = currentDoc.rows[0];

      // Guardar en histórico
      const historicoSql = `
        INSERT INTO historico_documentos (
          documento_id, version, archivo_fuente, archivo_pdf, estado,
          fecha, usuario_id, accion
        ) VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, $6, 'actualizado')
      `;

      await client.query(historicoSql, [
        current.id, current.version, current.archivo_fuente, current.archivo_pdf,
        current.estado, usuario_id
      ]);

      // Actualizar documento principal
      const {
        nombre, descripcion, gestion_id, convencion,
        archivo_fuente, archivo_pdf, estado,
        is_signed, signed_file_path, signer_name, signed_at, usuario_firmante
      } = updateData;

      const updateSql = `
        UPDATE documentos SET
          nombre = COALESCE($1, nombre),
          descripcion = COALESCE($2, descripcion),
          gestion_id = COALESCE($3, gestion_id),
          convencion = COALESCE($4, convencion),
          archivo_fuente = COALESCE($5, archivo_fuente),
          archivo_pdf = COALESCE($6, archivo_pdf),
          estado = COALESCE($7, estado),
          is_signed = COALESCE($8, is_signed),
          signed_file_path = COALESCE($9, signed_file_path),
          signer_name = COALESCE($10, signer_name),
          signed_at = COALESCE($11, signed_at),
          usuario_firmante = COALESCE($12, usuario_firmante),
          version = version + 1,
          fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE id = $13
        RETURNING *
      `;

      const result = await client.query(updateSql, [
        nombre, descripcion, gestion_id, convencion,
        archivo_fuente, archivo_pdf, estado,
        is_signed, signed_file_path, signer_name, signed_at, usuario_firmante,
        id
      ]);

      await client.query('COMMIT');
      return result.rows[0];

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Eliminar documento
   */
  static async delete(id) {
    const result = await query('DELETE FROM documentos WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  }

  /**
   * Obtener histórico de versiones de un documento
   */
  static async getHistorico(documento_id) {
    const sql = `
      SELECT h.*, 
             u.nombre as modificado_por
      FROM historico_documentos h
      LEFT JOIN users u ON h.usuario_id = u.id
      WHERE h.documento_id = $1
      ORDER BY h.fecha DESC
    `;

    const result = await query(sql, [documento_id]);
    return result.rows;
  }

  /**
   * Marcar documento como revisado
   */
  static async marcarRevisado(id, usuario_revisor, comentarios = null) {
    const sql = `
      UPDATE documentos SET
        estado = 'pendiente_aprobacion',
        usuario_revisor = $1,
        fecha_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $2 AND estado = 'pendiente_revision'
      RETURNING *
    `;

    const result = await query(sql, [usuario_revisor, id]);
    
    if (result.rows.length === 0) {
      throw new Error('Documento no encontrado o no está en estado pendiente de revisión');
    }

    // TODO: Aquí se podría agregar lógica para guardar comentarios en una tabla separada
    
    return result.rows[0];
  }

  /**
   * Marcar documento como aprobado
   */
  static async marcarAprobado(id, usuario_aprobador, comentarios = null) {
    const sql = `
      UPDATE documentos SET
        estado = 'aprobado',
        usuario_aprobador = $1,
        fecha_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $2 AND estado = 'pendiente_aprobacion'
      RETURNING *
    `;

    const result = await query(sql, [usuario_aprobador, id]);
    
    if (result.rows.length === 0) {
      throw new Error('Documento no encontrado o no está en estado pendiente de aprobación');
    }

    return result.rows[0];
  }

  /**
   * Rechazar documento
   */
  static async rechazar(id, usuario_id, comentarios = null) {
    const sql = `
      UPDATE documentos SET
        estado = 'rechazado',
        fecha_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await query(sql, [id]);
    
    if (result.rows.length === 0) {
      throw new Error('Documento no encontrado');
    }

    // TODO: Aquí se podría agregar lógica para guardar comentarios de rechazo
    
    return result.rows[0];
  }

  /**
   * Obtener documentos pendientes de revisión
   */
  static async getPendientesRevision() {
    const sql = `
      SELECT d.*, 
             g.nombre as gestion_nombre,
             uc.name as creador_nombre
      FROM documentos d
      LEFT JOIN gestiones g ON d.gestion_id = g.id
      LEFT JOIN users uc ON d.usuario_creador = uc.id
      WHERE d.estado = 'pendiente_revision'
      ORDER BY d.fecha_creacion ASC
    `;

    const result = await query(sql);
    return result.rows;
  }

  /**
   * Obtener documentos pendientes de aprobación
   */
  static async getPendientesAprobacion() {
    const sql = `
      SELECT d.*, 
             g.nombre as gestion_nombre,
             uc.name as creador_nombre,
             ur.name as revisor_nombre
      FROM documentos d
      LEFT JOIN gestiones g ON d.gestion_id = g.id
      LEFT JOIN users uc ON d.usuario_creador = uc.id
      LEFT JOIN users ur ON d.usuario_revisor = ur.id
      WHERE d.estado = 'pendiente_aprobacion'
      ORDER BY d.fecha_creacion ASC
    `;

    const result = await query(sql);
    return result.rows;
  }

  /**
   * Verificar si un código de documento ya existe
   */
  static async existeCodigo(codigo, excludeId = null) {
    let sql = 'SELECT COUNT(*) as count FROM documentos WHERE codigo = $1';
    const values = [codigo];

    if (excludeId) {
      sql += ' AND id != $2';
      values.push(excludeId);
    }

    const result = await query(sql, values);
    return parseInt(result.rows[0].count) > 0;
  }
}

module.exports = Documento;
