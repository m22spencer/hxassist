package hxassist;

import ds.IList;
using com.mindrocks.monads.instances.Prelude;
import com.mindrocks.monads.Monad.dO in DO;
using hxassist.Monads;

import haxe.ds.Option;

using sys.FileSystem;
using Alg;

class Run {
    static function main() new Run(Sys.args());

   
    function new(args:Iterable<String>) {
        trace(IList.ilist(args));
        //Get lib path from end of args 
        var list = IList.ilist(args).reverse();
        var expath = list.head();
        var libdir = Sys.getCwd();
        Sys.setCwd(expath);
        var list = list.tail().reverse();

        var vfs = new VFS('${libdir}temp836/');
        vfs.addClasspath(expath);

        function readArgs(args:IList<String>) {
            Alg.match(switch (args) {
                case {"-runTests"; l;}:
                    new test.TestMain();
                    readArgs(l);
                case {"--type"; file; tpath; pos; [];}:
                    var pos = Std.parseInt(pos);

                    AutoMake.fromFile(file)
                        (["-dce", "no",  "-D", "no-copt", "-cp", "C:/Users/Matthew/Documents/Github/hxassist/",
                            "--macro",
                            "haxe.macro.Compiler.addMetadata('@:build(test.TestBuilder.doBuildCheck("+pos+"))', '"+tpath+"')"], vfs.getTempDir());
                
                    Sys.exit(0);
                case {"--complete"; file; pos; [];}:
                    var pos = Std.parseInt(pos);
                    DO({
                            source <= vfs.read(file);
                            switch (source.charAt(pos-1)) {
                            case ".", "(": //Normal completion
                                AutoMake.fromFile(file)
                                    (["-D", "no-copt", "--display", '$file@$pos']);
                                None;
                            case " ": //Toplevel completion
                                vfs.modify(file, function(s) return DO({
                                            contents <= s;
                                            ret(contents.substr(0,pos) + "{hxassist.MacroBuilder.toplevel();}" + contents.substr(pos));
                                        }));
                                vfs.writeToFileSystem();
                                AutoMake.fromFile(file)
                                    (["-D", "no-copt"], vfs.getTempDir());
                                None;
                            case c: throw 'cannot complete on character $c';
                            }
                        });
                    Sys.exit(0);
                case {"--source"; file; contents; l;}:
                    vfs.modify(file, function(s) return Some(utils.Base64.decode(contents)));
                    readArgs(l);
                case {"--write"; l;}:
                    vfs.writeToFileSystem();
                    readArgs(l);
                case {cmd; _;}:
                    trace('unknown argument $cmd');
                case {[];}:
                    });
        }
        readArgs(list);
    }
}