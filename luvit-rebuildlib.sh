#!/usr/bin/env bash
#
# Create a better luvit library (libluvitb.a) where
# all symbols are available.

rm -f build/libluvitb.a

AR=${AR:-ar}
RANLIB=${RANLIB:-ranlib}

${AR} rvs build/libluvitb.a build/utils.o build/luv_fs.o \
    build/luv_dns.o build/luv_debug.o build/luv_handle.o build/luv_udp.o \
    build/luv_fs_watcher.o build/luv_timer.o build/luv_process.o build/luv_signal.o \
    build/luv_stream.o build/luv_tcp.o build/luv_tls.o build/luv_tls_conn.o \
    build/luv_pipe.o build/luv_poll.o build/luv_tty.o build/luv_misc.o build/luv.o \
    build/luvit_init.o build/lconstants.o build/lenv.o build/lyajl.o build/los.o \
    build/luv_zlib.o build/lhttp_parser.o \
    bundle/boundary.o bundle/buffer.o bundle/childprocess.o bundle/core.o bundle/dgram.o \
    bundle/dns.o bundle/fiber.o bundle/fs.o bundle/http.o bundle/https.o bundle/json.o \
    bundle/luvit_exports.o bundle/luvit_main.o \
    bundle/luvit.o bundle/mime.o bundle/module.o bundle/net.o bundle/path_base.o \
    bundle/path.o bundle/querystring.o bundle/repl.o bundle/stack.o bundle/timer.o \
    bundle/tls.o bundle/url.o bundle/utils.o bundle/uv.o bundle/zipreader.o \
    bundle/zlib.o deps/http-parser/http_parser.o deps/luacrypto/src/lcrypto.o

# OS X and SmarOS decided to be different, we'll have to copy these libs for them later...
OS_NAME="`uname -s`"
if [ "${OS_NAME}" != "Darwin" -a "${OS_NAME}" != "SunOS" ]; then

    cat <<EOF | ${AR} -M
open build/libluvitb.a
addlib deps/uv/libuv.a
addlib deps/cares/libcares.a
addlib deps/luajit/src/libluajit.a
addlib deps/yajl/yajl.a
addlib ../openssl/libssl.a
addlib ../openssl/libcrypto.a
addlib ../zlib/libz.a
save
end
EOF

fi

${RANLIB} build/libluvitb.a
