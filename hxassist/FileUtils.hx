package hxassist;

using sys.FileSystem;

using Alg;
import Alg.Fn;
import haxe.ds.Option;

using Lambda;

class FileUtils {
    /**
       Get the directory part of FILE
       Or null if no match
       dir/with/file.ext.bak -> dir/with/
       file.ext -> null
    **/
    public static function file_name_directory(file:String)
        return ~/(.*(?:\\|\/))?[^\\\/]*$/.let(Fn(
                if (_.match(file)) _.matched(1);
                else null));

    /**
       dir/with/file.ext.bak -> file.ext.bak
    **/
    public static function file_name_nondirectory(file:String)
        return StringTools.replace(file, file_name_directory(file), "");
    
    /**
       dir/with/file.ext.bak -> dir/with/file.ext
     **/
    public static function file_name_sans_ext(file:String)
        return file_name_directory(file) + file_base_name(file);
        
    /**
       dir/with/file.ext.bak -> file.ext
    **/
    public static function file_base_name(file:String) {
        return file_name_nondirectory(file)
            .let(Fn(_.substr(0, _.lastIndexOf("."))));
    }

    /**
       Finds all files upwards matching PATTERN
       Files are returned in oreder of closest to furthest
    **/
    public static function upward_match_files(dir:String, pattern:EReg):Iterable<String> {
        var ct = 1000;
        var matched:Iterable<String> = [];
        while (!isRoot(dir) && ct-- > 0) {
            matched = matched.concat(dir.readDirectory()
                .filter(Fn(pattern.match(_)))
                .map(Fn('$dir$_'))
                .list());
            dir = dir + "../";
        }
        return matched;
    }
    
    /**
       Check if root directory
    **/
    public static function isRoot(dir:String) {
        return (dir.fullPath() == (dir + "../").fullPath());
    }
}