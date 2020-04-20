--- mods related to higher level subject taxonomy

delete FROM public.taxonomy_parents_all;
delete FROM public.taxonomy where ttype='collection_areas';

INSERT INTO taxonomy (ttype, id, url, name, description, taxonomytype_id, created_at, updated_at) VALUES
('collection_areas', nextval('taxonomy_seq'),currval('taxonomy_seq'), 'Science, Technology & Medicine', 'Science, Technology & Medicine', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),('collection_areas', nextval('taxonomy_seq'),currval('taxonomy_seq'), 'Sport & Recreation', 'Sport & Recreation', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('collection_areas', nextval('taxonomy_seq'),currval('taxonomy_seq'), 'History', 'History', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('collection_areas', nextval('taxonomy_seq'),currval('taxonomy_seq'), 'Politics & Government', 'Politics & Government', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('collection_areas', nextval('taxonomy_seq'),currval('taxonomy_seq'), 'Arts & Culture', 'Arts & Culture', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('collection_areas', nextval('taxonomy_seq'),currval('taxonomy_seq'), 'Places', 'Places', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('collection_areas', nextval('taxonomy_seq'),currval('taxonomy_seq'), 'Society & Communities', 'Society & Communities', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('collection_areas', nextval('taxonomy_seq'),currval('taxonomy_seq'), 'Currently Working On', 'Currently Working On', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
