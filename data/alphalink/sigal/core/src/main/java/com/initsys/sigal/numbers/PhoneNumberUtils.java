package com.initsys.sigal.numbers;

public class PhoneNumberUtils {

	/**
	 * 10 digits or international to E.164:
	 * <dl>
	 * <dt>00 + xyz</dt>
	 * <dd>xyz
	 * <dd>
	 * <dt>xyz</dt>
	 * <dd>prefix + yz
	 * <dd>
	 * </dl>
	 * 
	 * @param number
	 * @param prefix
	 * @return
	 */
	public static String nationalToE164(String number, String prefix) {
		if (number.startsWith("00")) {
			return number.substring(2);
		}
		if (number.length() < 10) {
			return prefix + number;
		}
		return prefix + number.substring(1);
	}

	public static String e164toNational(String number, String prefix) {
		if (number.startsWith("+")) {
			number = number.substring(1);
		}

		if (number.startsWith(prefix)) {
			return "0" + number.substring(prefix.length());
		} if (number.startsWith("0")) {
		    // seems we are in a national numbering plan already TODO: can we remove this ?
		    return number;
		} else {
			return "00" + number;
		}
	}
}
