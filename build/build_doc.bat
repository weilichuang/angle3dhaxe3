haxe doc.hxml
cd/d ..
haxelib run dox -theme build/api_theme -i doc/documentation.xml -in com -in org -in msignal -in assets --title Angle3D -o doc 
cd/d doc
del /F documentation.xml