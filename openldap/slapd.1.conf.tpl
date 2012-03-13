# stand-alone slapd config -- for testing (with indexing)
# $OpenLDAP: pkg/ldap/tests/data/slapd.conf,v 1.39.2.10 2011/01/04 23:51:00 kurt Exp $
## This work is part of OpenLDAP Software <http://www.openldap.org/>.
##
## Copyright 1998-2011 The OpenLDAP Foundation.
## All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted only as authorized by the OpenLDAP
## Public License.
##
## A copy of this license is available in the file LICENSE in the
## top-level directory of the distribution or, alternatively, at
## <http://www.OpenLDAP.org/license.html>.

include		@H@/openldap/schema/core.schema
include		@H@/openldap/schema/cosine.schema
include		@H@/openldap/schema/inetorgperson.schema
include		@H@/openldap/schema/openldap.schema
include		@H@/openldap/schema/nis.schema
include		@H@/openldap/test.schema

#
pidfile		@H@/openldap/slapd.1.pid
argsfile	@H@/openldap/slapd.1.args

# allow big PDUs from anonymous (for testing purposes)
sockbuf_max_incoming 4194303

#mod#modulepath	../servers/slapd/back-bdb/
#mod#moduleload	back_bdb.la
#monitormod#modulepath ../servers/slapd/back-monitor/
#monitormod#moduleload back_monitor.la

#######################################################################
# database definitions
#######################################################################

database	bdb
suffix		"dc=example,dc=com"
rootdn		"cn=Manager,dc=example,dc=com"
rootpw		secret
#null#bind		on
directory	@H@/openldap/db.1.a
index		objectClass	eq
index		cn,sn,uid	pres,eq,sub
checkpoint		1024 5
#hdb#index		objectClass	eq
#hdb#index		cn,sn,uid	pres,eq,sub
#hdb#checkpoint		1024 5
#ndb#dbname db_1
#ndb#include ./testdata/ndb.conf

database	monitor
