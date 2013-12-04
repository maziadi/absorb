package com.initsys.sigal.vno;

import org.apache.commons.lang.StringUtils;

public class VnoUtils {
    /**
     * TODO
     * 
     * @param carrierCode
     * @return
     */
    public static String getVnoName(String carrierCode) {
        String[] carrierCodeParts = carrierCode.split("\\.");
        if (carrierCodeParts.length != 2) {
            throw new IllegalArgumentException(String.format(
                    "Carrier code '%s' should have 2 elements", carrierCode));
        } else if (StringUtils.isBlank(carrierCodeParts[0])) {
            throw new IllegalArgumentException(String.format(
                    "First part of carrier code '%s' is blank", carrierCode));
        }

        String vnoName = carrierCodeParts[0];
        return vnoName;
    }

    public static String composeCarrierCode(String vnoName,
            String faxNumberingPlanNumber) {

        return vnoName + "." + faxNumberingPlanNumber;
    }
}
