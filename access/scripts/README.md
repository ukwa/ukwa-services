README
======

CDX Modifications
-----------------

### Deletions

There are some 'manual overrides' in place on the CDX index. For example, there is currently a bug that means redirects to the archive itself are not handled properly (https://github.com/ukwa/ukwa-pywb/issues/72), so it's necessary to drop records that point back at the archive.

    $ curl -X POST --data-binary @cdx_records_to_delete.cdx http://cdx.api.wa.bl.uk/data-heritrix/delete

There are also take-down requests that require deletions. They are held in an internal repository.

### Aliases

As per [ukwa/ukwa-services#81](https://github.com/ukwa/ukwa-services/issues/81#issuecomment-1095116046) and [ukwa/ukwa-ui#369](https://github.com/ukwa/ukwa-ui/issues/369), we can use aliases to cope with sites that have changed URL over time.

    $ curl -X POST --data-binary @cdx_aliases_to_add.cdx http://cdx.api.wa.bl.uk/data-heritrix
