use inc::Module::Install;
name('Jifty-Plugin-NYTProf');
version('0.02');
requires('Jifty' => '1.00105');
requires('Devel::NYTProf' => 3.0);

WriteAll;
