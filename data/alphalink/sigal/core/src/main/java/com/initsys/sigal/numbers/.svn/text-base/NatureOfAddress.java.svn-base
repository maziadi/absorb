package com.initsys.sigal.numbers;

public enum NatureOfAddress {

	NATIONAL,

	INTERNATIONAL,

	SPECIAL;

	public String decimal() {
		if (this == NATIONAL) {
			return "003";
		} else if (this == INTERNATIONAL) {
			return "004";
		} else if (this == SPECIAL) {
			return "115";
		} else {
			throw new RuntimeException("Should not have happened");
		}
	}

	public String decimalWithoutLeadingZero() {
		if (this == NATIONAL) {
			return "3";
		} else if (this == INTERNATIONAL) {
			return "4";
		} else if (this == SPECIAL) {
			return "115";
		} else {
			throw new RuntimeException("Should not have happened");
		}
	}

	public Short toShort() {
		if (this == NATIONAL) {
			return new Short((short) 3);
		} else if (this == INTERNATIONAL) {
			return new Short((short) 4);
		} else if (this == SPECIAL) {
			return new Short((short) 115);
		} else {
			throw new RuntimeException("Should not have happened");
		}
	}

	public static NatureOfAddress decode(String decimal) {
		if ("003".equals(decimal) || "3".equals(decimal)) {
			return NATIONAL;
		} else if ("004".equals(decimal) || "4".equals(decimal)) {
			return INTERNATIONAL;
		} else if ("115".equals(decimal)) {
			return SPECIAL;
		} else {
			throw new IllegalArgumentException("Unrecognized value '" + decimal
					+ "'");
		}
	}

	public static NatureOfAddress decode(Short decimal) {
		if (3 == decimal) {
			return NATIONAL;
		} else if (4 == decimal) {
			return INTERNATIONAL;
		} else if (115 == decimal) {
			return SPECIAL;
		} else {
			throw new IllegalArgumentException("Unrecognized value '" + decimal
					+ "'");
		}
	}

	public static boolean isNadiValid(Short value) {
	    if (value == null) {
	        return false;
	    }
	    
	    return 3 == value || 4 == value || 115 == value;
	}
	

}
