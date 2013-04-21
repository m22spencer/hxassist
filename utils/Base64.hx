//https://github.com/outbounder/org.abn.haxe/blob/master/src/util/Base64.hx

package utils;

/**
   Base64 utility.
*/
class Base64 {

  public static var CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  public static function fillNullbits( s : String ) : String {
    while( s.length % 3 != 0 )
      s += "=";
    return s;
  }

  public static function removeNullbits( s : String ) : String {
    while( s.charAt( s.length-1 ) == "=" )
      s = s.substr( 0, s.length-1 );
    return s;
  }

  public static inline function encode( t : String ) : String {
    return fillNullbits( haxe.crypto.BaseCode.encode( t, CHARS ) );
  }

  public static inline function decode( t : String ) : String {
    return haxe.crypto.BaseCode.decode( removeNullbits( t ), CHARS );
  }
}