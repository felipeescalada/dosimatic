-- PostgreSQL database schema for SecWin document management system
-- Generated from database dump

-- Create ENUM types
CREATE TYPE public.convencion_tipo AS ENUM (
    'Manual',
    'Procedimiento',
    'Instructivo',
    'Formato',
    'Documento Externo'
);

CREATE TYPE public.estado_doc AS ENUM (
    'pendiente_revision',
    'pendiente_aprobacion',
    'aprobado',
    'rechazado',
    'eliminado'
);

-- Create function for updating timestamps
CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Create sequences
CREATE SEQUENCE public.document_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.documentos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.documents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.gestiones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.historico_documentos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Create tables
CREATE TABLE public.document_versions (
    id integer NOT NULL,
    document_id integer NOT NULL,
    version integer NOT NULL,
    original_filename character varying(255) NOT NULL,
    storage_path character varying(500) NOT NULL,
    mime_type character varying(100),
    size_bytes bigint,
    is_signed boolean DEFAULT false,
    signed_pdf_path character varying(500),
    created_by character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.documentos (
    id integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nombre character varying(255) NOT NULL,
    descripcion text,
    gestion_id integer NOT NULL,
    convencion public.convencion_tipo NOT NULL,
    vinculado_a integer,
    archivo_fuente character varying(255),
    archivo_pdf character varying(255),
    version integer DEFAULT 1,
    estado public.estado_doc DEFAULT 'pendiente_revision'::public.estado_doc,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    usuario_creador integer,
    usuario_revisor integer,
    usuario_aprobador integer,
    fecha_revision timestamp without time zone,
    fecha_aprobacion timestamp without time zone,
    comentarios_revision text,
    comentarios_aprobacion text
);

CREATE TABLE public.documents (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    created_by character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.gestiones (
    id integer NOT NULL,
    nombre character varying(255) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.historico_documentos (
    id integer NOT NULL,
    documento_id integer NOT NULL,
    version integer NOT NULL,
    archivo_fuente character varying(255),
    archivo_pdf character varying(255),
    estado public.estado_doc,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    usuario_id integer,
    comentarios text,
    accion character varying(100)
);

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    rol character varying(50) DEFAULT 'usuario'::character varying,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    password character varying(255),
    reset_token character varying(255),
    reset_token_expires timestamp without time zone,
    signature_image character varying(255)
);

-- Set default values for sequences
ALTER TABLE ONLY public.document_versions ALTER COLUMN id SET DEFAULT nextval('public.document_versions_id_seq'::regclass);
ALTER TABLE ONLY public.documentos ALTER COLUMN id SET DEFAULT nextval('public.documentos_id_seq'::regclass);
ALTER TABLE ONLY public.documents ALTER COLUMN id SET DEFAULT nextval('public.documents_id_seq'::regclass);
ALTER TABLE ONLY public.gestiones ALTER COLUMN id SET DEFAULT nextval('public.gestiones_id_seq'::regclass);
ALTER TABLE ONLY public.historico_documentos ALTER COLUMN id SET DEFAULT nextval('public.historico_documentos_id_seq'::regclass);
ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);

-- Set sequence ownership
ALTER SEQUENCE public.document_versions_id_seq OWNED BY public.document_versions.id;
ALTER SEQUENCE public.documentos_id_seq OWNED BY public.documentos.id;
ALTER SEQUENCE public.documents_id_seq OWNED BY public.documents.id;
ALTER SEQUENCE public.gestiones_id_seq OWNED BY public.gestiones.id;
ALTER SEQUENCE public.historico_documentos_id_seq OWNED BY public.historico_documentos.id;
ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;

-- Create constraints
ALTER TABLE ONLY public.document_versions
    ADD CONSTRAINT document_versions_document_id_version_key UNIQUE (document_id, version),
    ADD CONSTRAINT document_versions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT documentos_codigo_key UNIQUE (codigo),
    ADD CONSTRAINT documentos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.gestiones
    ADD CONSTRAINT gestiones_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.historico_documentos
    ADD CONSTRAINT historico_documentos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email),
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);

-- Create indexes
CREATE INDEX idx_document_versions_document_id ON public.document_versions USING btree (document_id);
CREATE INDEX idx_document_versions_version ON public.document_versions USING btree (document_id, version);
CREATE INDEX idx_documents_created_by ON public.documents USING btree (created_by);
CREATE INDEX idx_historico_documento ON public.historico_documentos USING btree (documento_id);

-- Create triggers
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_gestiones_updated_at BEFORE UPDATE ON public.gestiones FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create foreign key constraints
ALTER TABLE ONLY public.document_versions
    ADD CONSTRAINT document_versions_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT documentos_gestion_id_fkey FOREIGN KEY (gestion_id) REFERENCES public.gestiones(id) ON DELETE CASCADE,
    ADD CONSTRAINT documentos_usuario_aprobador_fkey FOREIGN KEY (usuario_aprobador) REFERENCES public.usuarios(id) ON DELETE SET NULL,
    ADD CONSTRAINT documentos_usuario_creador_fkey FOREIGN KEY (usuario_creador) REFERENCES public.usuarios(id) ON DELETE SET NULL,
    ADD CONSTRAINT documentos_usuario_revisor_fkey FOREIGN KEY (usuario_revisor) REFERENCES public.usuarios(id) ON DELETE SET NULL,
    ADD CONSTRAINT documentos_vinculado_a_fkey FOREIGN KEY (vinculado_a) REFERENCES public.documentos(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.historico_documentos
    ADD CONSTRAINT historico_documentos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);

-- Insert sample data
INSERT INTO public.gestiones (nombre, descripcion) VALUES 
('Gestión de Calidad', 'Documentos relacionados con el sistema de gestión de calidad'),
('Recursos Humanos', 'Documentos de gestión de personal y recursos humanos'),
('Finanzas', 'Documentos financieros y contables'),
('Operaciones', 'Documentos operativos y de procesos');

-- Insert users with bcrypt hashed passwords (password: admin123)
INSERT INTO public.usuarios (nombre, email, password, rol, activo) VALUES 
('Administrador Sistema', 'admin.docs@empresa.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', true),
('Gerente General', 'gerente@empresa.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'gerente', true),
('Juan Pérez', 'juan.perez@empresa.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'creador', true),
('María García', 'maria.garcia@empresa.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'revisor', true),
('Carlos López', 'carlos.lopez@empresa.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'aprobador', true)
ON CONFLICT (email) DO NOTHING;
