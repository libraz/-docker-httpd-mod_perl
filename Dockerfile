FROM alpine:3.7
LABEL maintainer "libraz <libraz@libraz.net>"
LABEL version="18.060901"

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

#// openssl-dev conflicts mariadb-dev
RUN \
	apk update && \
	apk --update add \
		tzdata bash sudo curl shadow make gcc g++ musl-dev \
		perl=5.26.2-r0 perl-dev=5.26.2-r0 \
		libtool libxml2 libxml2-dev expat-dev gmp gmp-dev freetype freetype-dev \
		tiff tiff-dev giflib giflib-dev gd gd-dev openssl \
		mysql-client mariadb-dev \
		apache2-mod-perl@testing apache2-mod-perl-dev@testing apache2-utils apache2-ctl openrc && \
	cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
	apk del tzdata && \
	rm -rf /var/lib/apt/lists/* /var/cache/apk/* /usr/lib/mysqld* /usr/bin/mysql*

RUN cd /tmp && \
	wget http://chasen.org/~taku/software/darts/src/darts-0.32.tar.gz && \
	tar zxf darts-0.32.tar.gz && \
	cd /tmp/darts-0.32 && \
	./configure && make && make install && \
	ln -s /usr/local/libexec/darts/mkdarts /usr/local/bin/mkdarts && \
	rm -rf /tmp/darts-0.32

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
	&& cpanm DBD::mysql Text::Darts\
	&& rm -rf /root/.cpanm

EXPOSE 80
