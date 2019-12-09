FROM centos:centos6 as builder

RUN set -x \
	&& yum -y install yum-plugin-fastestmirror \
	&& echo "include_only=.jp" >>  /etc/yum/pluginconf.d/fastestmirror.conf \
	&& echo "prefer=ftp.riken.jp">>  /etc/yum/pluginconf.d/fastestmirror.conf \
	&& yum -y update \
	&& yum -y install libtool wget gcc gcc-c++ patch pcre-devel openssl-devel \
	&& yum -y install perl perl-devel perl-ExtUtils-MakeMaker perl-CPAN perl-ExtUtils-Embed \
	&& yum -y install libxml2-devel zlib-devel expat-devel gmp-devel freetype freetype-devel \
	&& yum -y install libpng libpng-devel libtiff libtiff-devel giflib giflib-devel gd gd-devel \
	&& yum -y install libjpeg-turbo libjpeg-turbo-devel \
	&& cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

ENV APR_VERSION 1.7.0
ENV APR_UTIL_VERSION 1.6.1
ENV HTTPD_VERSION 2.4.41

RUN set -x \
	&& cd /tmp \
	&& wget http://ftp.jaist.ac.jp/pub/apache/apr/apr-${APR_VERSION}.tar.gz \
	&& wget http://ftp.jaist.ac.jp/pub/apache/apr/apr-util-${APR_UTIL_VERSION}.tar.gz \
	&& wget http://ftp.jaist.ac.jp/pub/apache/httpd/httpd-${HTTPD_VERSION}.tar.gz \
	&& tar xzf apr-${APR_VERSION}.tar.gz \
	&& cd apr-${APR_VERSION} \
	&& ./configure && make && make install \
	&& cd .. \
	&& tar xzf apr-util-${APR_UTIL_VERSION}.tar.gz \
	&& cd apr-util-${APR_UTIL_VERSION} \
	&& ./configure --with-apr=/usr/local/apr && make && make install \
	&& cd .. \
	&& tar xzf httpd-${HTTPD_VERSION}.tar.gz \
	&& cd httpd-${HTTPD_VERSION} \
	&& ./configure \
		--with-apr=/usr/local/apr \
		--with-apr-util=/usr/local/apr \
		--enable-modules=all \
		--enable-mods-shared=all \
		--with-mpm=worker \
		--enable-mpms-shared='prefork worker event'\
	&& make && make install \
	&& cp ./build/rpm/httpd.init /etc/init.d/httpd \
	&& sed -i -e "s|/usr/sbin/httpd|/usr/local/apache2/bin/httpd|" /etc/init.d/httpd \
	&& sed -i -e "s|/etc/httpd/conf/httpd.conf|/usr/local/apache2/conf/httpd.conf|" /etc/init.d/httpd \
	&& sed -i -e "s|/var/log/httpd/httpd.pid|/var/run/httpd.pid|" /etc/init.d/httpd \
  && sed -i -e "s|/var/log/httpd/\${prog}.pid|/var/run/httpd.pid|" /etc/init.d/httpd \
	&& cd .. \
	&& rm -rf apr-${APR_VERSION}* apr-util-${APR_UTIL_VERSION}* httpd-${HTTPD_VERSION}*

ENV MOD_PERL_VERSION 2.0.11

RUN set -x \
	&& cd /tmp \
	&& wget https://archive.apache.org/dist/perl/mod_perl-${MOD_PERL_VERSION}.tar.gz \
	&& tar zxf mod_perl-${MOD_PERL_VERSION}.tar.gz \
	&& cd mod_perl-${MOD_PERL_VERSION} \
	&& perl Makefile.PL MP_AP_PREFIX=/usr/local/apache2 \
	&& make \
	&& make install \
	&& cd .. \
	&& rm -rf mod_perl-${MOD_PERL_VERSION}*

WORKDIR /usr/local/bin
ENV PERL_CPANM_OPT "--no-wget -n --mirror http://ftp.jaist.ac.jp/pub/CPAN/ --local-lib=/usr/local/perl"
ENV PERL5OPT "-Mlib=/usr/local/perl/lib"
ENV PERL5LIB /usr/local/perl/lib/perl5/

RUN set -x \
  && curl -L -O http://xrl.us/cpanm \
	&& mkdir -p ${PERL5LIB} \
	&& chmod +x cpanm \
	&& cpanm local::lib Carton \
	&& cpanm Time::HiRes Test::More Encode Web::Scraper Class::Inspector Class::Data::Inheritable Log::Handler Imager \
	&& cpanm Class::Accessor::Fast Cache::Memcached::Fast HTML::Template::Pro Imager::QRCode Log::Minimal \
	&& cpanm Digest::MD5 Storable MIME::Tools Exporter Unicode::Japanese CGI HTML::FillInForm \
	&& cpanm Calendar::Japanese::Holiday File::Pid parent Encode::JP::Mobile Lingua::EN::Inflect::Number \
	&& cpanm YAML::Syck Image::Size SQL::Statement CGI::Session \
	&& cpanm Archive::Tar IPC::ShareLite Template DBI DBIx::Simple Params::Validate Error \
	&& cpanm Net::DNS SQL::Abstract Hash::Merge Attribute::Handlers Switch \
	&& cpanm URL::Encode::XS Compress::Zlib RedisDB JSON::XS Search::QueryParser \
	&& cpanm Net::Twitter Imager::Filter::Sepia Image::ExifTool Statistics::Lite \
	&& cpanm http://search.cpan.org/CPAN/authors/id/M/MI/MIYAGAWA/HTML-Selector-XPath-0.08.tar.gz \
	&& rm -rf /root/.cpanm

RUN set -x \
	&& cd /tmp \
	&& wget http://chasen.org/~taku/software/darts/src/darts-0.32.tar.gz \
	&& tar zxf darts-0.32.tar.gz \
	&& cd /tmp/darts-0.32 \
	&& ./configure && make && make install \
	&& ln -s /usr/local/libexec/darts/mkdarts /usr/local/bin/mkdarts \
	&& cpanm Text::Darts \
	&& rm -rf /tmp/darts-0.32*

RUN set -x \
	&& yum -y localinstall http://dev.mysql.com/get/mysql57-community-release-el6-8.noarch.rpm \
	&& yum -y install mysql-community-client mysql-community-devel \
	&& cpanm DBD::mysql \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all \
	&& rm -rf /root/.cpanm

FROM centos:centos6
LABEL maintainer "libraz <libraz@libraz.net>"
LABEL version="19.120101"

RUN set -x \
	&& yum -y install yum-plugin-fastestmirror \
	&& yum -y localinstall http://dev.mysql.com/get/mysql57-community-release-el6-11.noarch.rpm \
	&& echo "include_only=.jp" >>  /etc/yum/pluginconf.d/fastestmirror.conf \
	&& echo "prefer=ftp.riken.jp">>  /etc/yum/pluginconf.d/fastestmirror.conf \
	&& yum -y update \
	&& yum -y install initscripts perl perl-ExtUtils-MakeMaker perl-CPAN perl-ExtUtils-Embed \
	&& yum -y install freetype libpng libtiff giflib gd libjpeg-turbo \
	&& yum -y install mysql-community-client \
	&& cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

COPY --from=builder /usr/local/ /usr/local/
COPY --from=builder /etc/init.d/httpd /etc/init.d/httpd

ENV PERL_CPANM_OPT "--no-wget -n --mirror http://ftp.jaist.ac.jp/pub/CPAN/ --local-lib=/usr/local/perl"
ENV PERL5OPT "-Mlib=/usr/local/perl/lib"
ENV PERL5LIB /usr/local/perl/lib/perl5/

EXPOSE 80
