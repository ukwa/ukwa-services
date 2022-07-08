SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: documents_found; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents_found (
    document_url character varying(4096) NOT NULL,
    title text,
    filename character varying(1024) NOT NULL,
    landing_page_url character varying(4096) NOT NULL,
    source character varying(4096) NOT NULL,
    wayback_timestamp character varying(14) NOT NULL,
    launch_id character varying(255),
    job_name character varying(255) NOT NULL,
    size integer NOT NULL,
    target_id integer,
    status character varying(255) NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: documents_found documents_found_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents_found
    ADD CONSTRAINT documents_found_pkey PRIMARY KEY (document_url);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- PostgreSQL database dump complete
--


--
-- Dbmate schema migrations
--

INSERT INTO public.schema_migrations (version) VALUES
    ('20211123222500');
