# Copyright 2013 Afiniate All Rights Reserved.


NAME := aws_async
LICENSE := "OSI Approved :: Apache Software License v2.0"
AUTHOR := "Afiniate, Inc."
HOMEPAGE := "https://github.com/afiniate/aws_async"

DEV_REPO := "git@github.com:afiniate/aws_async.git"
BUG_REPORTS := "https://github.com/afiniate/aws_async/issues"

DESC="Async based interface to AWS services"

BUILD_DEPS := vrt
DEPS=core async async_unix cohttp sexplib atdgen uri cryptokit \
     async_shell xmlm

vrt.mk:
	vrt prj gen-mk

-include vrt.mk
