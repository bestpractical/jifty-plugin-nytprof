use inc::Module::Install;
name('Jifty-Plugin-NYTProf');
version('0.02');
requires('Jifty' => '0.90422');
requires('Devel::NYTProf' => 3.0);

WriteAll;
