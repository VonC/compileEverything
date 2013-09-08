#!/bin/bash
ctld stop
rm $H/apache/gitweb_error_log
ctld start