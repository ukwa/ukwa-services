// The search fields and filterable facets you want
const fields = [
        {label: "All text fields", field: "*", type: "text"},
        {label: "Collection", field: "collection_s", type: "list-facet"},
        {label: "Stream", field: "collection_s", type: "list-facet"},
        {label: "Year", field: "year_i", type: "range-facet"},
        {label: "Kind", field: "kind_s", type: "list-facet"}
];

// The sortable fields you want
const sortFields = [
        {label: "File date", field: "timestamp_dt"},
        {label: "File name", field: "file_name_s"},
        {label: "File size", field: "file_size_l"},
        {label: "File date last seen", field: "refresh_date_dt"},
        {label: "Relevance", field: "score"}
];

maxFacets = 100;

