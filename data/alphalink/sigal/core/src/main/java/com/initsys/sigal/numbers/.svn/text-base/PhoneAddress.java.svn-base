package com.initsys.sigal.numbers;

public class PhoneAddress {

    public static final String SHORT_NUMBERS_PREFIX = "015";

    private String number;

    private NatureOfAddress natureOfAddress;

    public PhoneAddress() {
        // empty
    }

    public PhoneAddress(String number, NatureOfAddress natureOfAddress) {
        setNumber(number);
        setNatureOfAddress(natureOfAddress);
    }

    public String getNumber() {
        return number;
    }

    public void setNumber(String number) {
        this.number = number;
    }

    public NatureOfAddress getNatureOfAddress() {
        return natureOfAddress;
    }

    public String getNadi() {
        return getNatureOfAddress().decimalWithoutLeadingZero();
    }

    public String getCallingNadi() {
      if(NatureOfAddress.SPECIAL == getNatureOfAddress()) {
        return NatureOfAddress.NATIONAL.decimalWithoutLeadingZero();
      }

      return getNatureOfAddress().decimalWithoutLeadingZero();
    }

    public void setNatureOfAddress(NatureOfAddress natureOfAddress) {
        this.natureOfAddress = natureOfAddress;
    }

    public static PhoneAddress fromE164(String number, String localPrefix) {
        if (number.startsWith("+")) {
            number = number.substring(1);
        }
        if (number.startsWith(SHORT_NUMBERS_PREFIX)) {
            return new PhoneAddress(number.substring(SHORT_NUMBERS_PREFIX
                    .length()), NatureOfAddress.SPECIAL);
        } else if (number.startsWith(localPrefix)) {
            number = number.substring(localPrefix.length());

            if (number.length() < 9) {
                return new PhoneAddress(number, NatureOfAddress.SPECIAL);
            } else {
                return new PhoneAddress(number, NatureOfAddress.NATIONAL);
            }
        } else {
            return new PhoneAddress(number, NatureOfAddress.INTERNATIONAL);
        }
    }

    public String e164Number(String prefix) {
        if (NatureOfAddress.INTERNATIONAL == getNatureOfAddress()) {
            return getNumber();
        } else {
            return prefix + getNumber();
        }
    }

    public static PhoneAddress parse(String str) {
        return new PhoneAddress(str.substring(3), NatureOfAddress.decode(str
                .substring(0, 3)));
    }

    public String addressNumber() {
      return getNatureOfAddress().decimal() + getNumber();
    }
}

