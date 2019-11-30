FROM httpd:2.4.41-alpine
LABEL maintainer "libraz <libraz@libraz.net>"
LABEL version="19.120101"

RUN apk update \
	&& apk --no-cache --update add \
		tzdata bash sudo curl shadow make gcc g++ musl-dev \
		perl perl-dev \
		libtool libxml2 libxml2-dev expat-dev gmp gmp-dev freetype freetype-dev \
		tiff tiff-dev giflib giflib-dev gd gd-dev openssl openssl-dev \
		libc-dev zlib-dev \
	&& cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
	&& apk del tzdata \
	&& rm -rf /var/lib/apt/lists/* /var/cache/apk/*

RUN cd /tmp \
	&& wget http://ftp.riken.jp/net/apache/perl/mod_perl-2.0.11.tar.gz \
	&& ln -s /usr/lib/x86_64-linux-gnu/libgdbm.so.3.0.0 /usr/lib/libgdbm.so \
	&& tar zxf mod_perl-2.0.11.tar.gz \
	&& cd mod_perl-2.0.11 \
	&& perl Makefile.PL MP_AP_PREFIX=/usr/local/apache2 \
	&& make \
	&& make install \
	&& cd .. \
	&& rm -r mod_perl-2.0.11*

WORKDIR /usr/bin
ENV PERL_CPANM_OPT "--no-wget -n --mirror http://ftp.nara.wide.ad.jp/pub/CPAN/"

RUN curl -LO https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm \
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

RUN cd /tmp \
	&& wget http://chasen.org/~taku/software/darts/src/darts-0.32.tar.gz \
	&& tar zxf darts-0.32.tar.gz \
	&& cd /tmp/darts-0.32 \
	&& ./configure \
	&& make \
	&& make install \
	&& ln -s /usr/local/libexec/darts/mkdarts /usr/local/bin/mkdarts \
	&& cpanm Text::Darts \
	&& rm -rf /tmp/darts-0.32* /root/.cpanm

RUN apk update \
	&& apk --no-cache --update add \
		mysql-client mariadb-dev \
	&& cpanm DBD::mysql \
	&& rm -rf /var/lib/apt/lists/* /var/cache/apk/* /usr/lib/mysqld* /usr/bin/mysql* /root/.cpanm

EXPOSE 80
