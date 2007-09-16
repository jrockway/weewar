use inc::Module::Install;

name('Weewar');
all_from('lib/Weewar.pm');

requires 'XML::LibXML';
requires 'LWP::UserAgent';
requires 'Class::Accessor';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
