curl "http://solr.api.wa.bl.uk/solr/admin/collections?action=CREATEALIAS&name=all&collections=NPLD-FC2013-20190220,NPLD-FC2014-20190221,NPLD-FC2015-20190225,NPLD-FC2016-20190226,NPLD-FC2017-20190228,NPLD-DC2013-20190207,NPLD-DC2014-20190305,NPLD-DC2015-20190311,selective-20190221&wt=json"

# V2 API
#curl -X POST http://solr.api.wa.bl.uk/solr/api/collections -H 'Content-Type: application/json' -d '
#  {
#    "create-alias":{
#      "name":"testalias",
#      "collections":["NPLD-FC2013-20190220","NPLD-FC2014-20190221","NPLD-FC2015-20190225","NPLD-FC2016-20190226","NPLD-FC2017-20190228","NPLD-DC2013-20190207","NPLD-DC2014-20190305","NPLD-DC2015-20190311","selective-20190221"]
#    }
#  }
#'
