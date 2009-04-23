use inc::Module::Install;
name('Jifty-Plugin-NYTProf');
version('0.01');
requires('Jifty' => '0.90220');
requires('Devel::NYTProf' => 2.10);

WriteAll;
