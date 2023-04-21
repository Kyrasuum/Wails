package unit.crypto;

import unit.Test;
import haxe.Timer;
import haxe.io.Bytes;
import haxe.crypto.RC4;

class RC4Test extends Test
{
	var keys = [
		"676F6F646E657373",
		"736563726574206B6579",
		"4861786520697320616E206F70656E20736F7572636520746F6F6C6B6974206261736564206F6E2061206D6F6465726E2C2068696768"
	];

	var plainText = [
		"48617865206973206E6F7420612068696768206C6576656C206672616D65776F726B2E2049742773206120746F6F6C6B697420746861742063616E206265207573656420746F206275696C642063726F73732D706C6174666F726D20746F6F6C7320616E64206672616D65776F726B73",
		"4861786520697320757365642062792074686F7573616E6473206F6620646576656C6F7065727320776F726C647769646520746F206275696C642067616D65732C20617070732C20746F6F6C732C20616E64206672616D65776F726B732E205365766572616C20686967682070726F66696C6520636F6D70616E69657320617265207573696E672048617865",
		"4861786520697320616E206F70656E20736F7572636520746F6F6C6B6974206261736564206F6E2061206D6F6465726E2068696768206C6576656C207374726963746C792074797065642070726F6772616D6D696E67206C616E67756167652C20612073746174652D6F662D7468652D617274206C696768742D73706565642063726F73732D636F6D70696C65722C206120636F6D706C6574652063726F73732D706C6174666F726D207374616E64617264206C6962726172792C20616E64207761797320746F2061636365737320746F206561636820706C6174666F726D2773206E6174697665206361706162696C69746965732E20"
	];

	var ciphers = [
		"C52D14CA9A35798382B5F4543D1BA2185FEB59EDCFCB8DFB9CE6842A8754F745B9497ACEE8273F080FB4138E7106B0139F15C99F79727DAAFEC08200A16F2DA2739E752446C018BBB450009053B77814955DC8D15CC3C3E85CCFD46E2518274D460270D3A48F32B24706B4E0DD8522C4",
		"2488DC99595464491C1F3BD9C687851ED7D1E6EB2932D7D31D868A7A8B7438B7A6B0E163838BDCDC1A79679D082EEDC394C682A14C1463326E3E1157D8B0366D4E5010D45A325C20435514E278A1E5D6F0954455C3189C1CF18E94B70812E6EDE0D50E0EE4AAD29D9769F97D8F37BB97FEE62C64CAD53C4EBF9DE4F319A35100D39570200D22C2F192146788",
		"78FB7BD417EB961227133F20A8E744E3DE52FB873370D6599524111CBA1552842095AC3F91FFF1B813218AE8E1F9C64F1E66A8B3AFC4AE44FCC2CBCE00177EB41CDC4ECCF0EBCA35C7F081C06093C11F20CFD65AC5D801C538760FC871B3946076C7CDF47F46087FCEF8B7BED95EA078E5863FC078F5DEE195E9D2A8A52374285134B49E39270EBDA08E0991972A848822CCBC4D0CCC02B6F3DE0B9BEC4184AFF2C0914584AE15682F4CB8405E92A8EE73EBD5A54F8253EBE4E1C86C2D40EAAD8BD88B6104E3B654B17B8FF977E11B2B2CADB894B285D21642D5C2BAFBE4763E8A4F418ACEEBA1677C3EF0AEAD9E9BD239E93587F63CD2"
	];

	public function test_rc4():Void
	{
		trace("RC4 for "+keys.length+" keys");
		var time = Timer.stamp();
		for(i in 0...keys.length)
		{
			var key = Bytes.ofHex(keys[i]);
			var text = Bytes.ofHex(plainText[i]);
			var rc4 = new RC4();
			rc4.init(key);
			var enc = rc4.encrypt(text);
			eq( enc.toHex().toUpperCase(), ciphers[i] );
			rc4.init(key);
			var decr = rc4.decrypt(enc);
			eq( decr.toHex().toUpperCase(), plainText[i] );
			}
		time = Timer.stamp()-time;
		trace("Finished : "+time+" seconds");
	}
}