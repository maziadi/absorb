package com.initsys.sigal.agent.agi.ss7;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;

public class IsupInRdnis {
	/** private final static Pattern FULL_PATTERN = Pattern */
	/** 		.compile("^(SMG.*)-(CPC-.*?)(-GEN-.*?)??(-RED-.*?)??(-IAM-.*?)??$"); */

    /** msg 4.x : X-FreeTDM-CPC */
    public final static String XF_CPC = "X-FreeTDM-CPC";
    public final static String XF_DEFAULT_CPC = "ordinary";

    /** msg 4.x : X-FreeTDM-GN Q.763 3.26 */
    private final static String XF_GN = "X-FreeTDM-GN";
    private final static String XF_GN_NUMQUAL = "X-FreeTDM-GN-NumQual";
    private final static String XF_GN_NADI = "X-FreeTDM-GN-NADI";
    private final static String XF_GN_SCREEN = "X-FreeTDM-GN-Screen";
    private final static String XF_GN_PRES = "X-FreeTDM-GN-Presentation";
    private final static String XF_GN_PLAN = "X-FreeTDM-GN-Plan";
    // X-FreeTDM-GN-NumInComp

    /** msg 4.x : X-FreeTDM-RDNIS  Q.763 3.44 */
    private final static String XF_RDNIS = "X-FreeTDM-RDNIS";
    private final static String XF_RDNIS_NUMQUAL = "X-FreeTDM-RDNIS-NumQual"; // TODO SMG
    private final static String XF_RDNIS_NADI = "X-FreeTDM-RDNIS-NADI";
    private final static String XF_RDNIS_SCREEN = "X-FreeTDM-RDNIS-Screen";
    private final static String XF_RDNIS_PRES = "X-FreeTDM-RDNIS-Presentation";
    private final static String XF_RDNIS_PLAN = "X-FreeTDM-RDNIS-Plan";

    /** msg 4.x : X-FreeTDM-RDNIS  Q.763 3.45 */
    private final static String XF_RDINF_ORIG = "X-FreeTDM-RDINF-Orig"; // TODO SMG
    private final static String XF_RDINF_INDICATOR = "X-FreeTDM-RDINF-Indicator";
    private final static String XF_RDINF_ORIG_REASON = "X-FreeTDM-RDINF-OrigReason";
    private final static String XF_RDINF_REASON = "X-FreeTDM-RDINF-Reason";
    private final static String XF_RDINF_COUNT = "X-FreeTDM-RDINF-Count";
    private final static String XF_RDINF_RES = "X-FreeTDM-RDINF-Reserved"; // TODO SMG

    /** msg 4.x : X-FreeTDM-IAM */
    private final static String XF_IAM = "X-FreeTDM-IAM";

    /** nsg 4.x : X-FREETDM-CLD-NADI */
    public final static String XF_CLD_NADI = "X-FreeTDM-CLD-NADI";

    /** nsg 4.x : X-FREETDM-CLG-NADI */
    public final static String XF_CLG_NADI = "X-FreeTDM-CLG-NADI";
    public final static String XF_CLG_SCREEN = "X-FreeTDM-Screen";
    public final static String XF_CLG_PRES = "X-FreeTDM-Presentation";

    private final static Pattern CPC_PATTERN = Pattern
        .compile("^unknown|operator-french|operator-english|operator-german|operator-russian|operator-spanish|ordinary|priority|data-call|test-call|payphone$");

	/** logger */
	private static final Logger log = LoggerFactory.getLogger(IsupInRdnis.class);

	private String callingPartyIndicator;

	/** ISUPinRDNIS called number / Nature of Address Indicator */
	private Short calledNadi;

	/** ISUPinRDNIS calling number / Nature of Address Indicator */
	private Short callingNadi;

	/** ISUPinRDNIS calling number / Screen Indicator */
	private Short callingScreen;

	/** ISUPinRDNIS calling number / Pres */
	private Short callingPres;

	/** ISUPinRDNIS calling number / GEN ou ISUP */
	private String callingUsedType;

	/** ISUPinRDNIS generic number / Address Presentation Indicator */
	private Short genAddressPresentationIndicator;

	/** ISUPinRDNIS generic number / Address Screening Indicator */
	private Short genAddressScreeningIndicator;

	/** ISUPinRDNIS generic number / Nature of Address Indicator */
	private Short genNadi;

	/** ISUPinRDNIS generic number / Number Plan Indicator */
	private Short genNumberPlanIndicator;

	/** ISUPinRDNIS generic number / Number Qualifier Indicator */
	private Short genNumberQualifierIndicator;

	/** ISUPinRDNIS generic number / Number */
	private String genNumber;

	/** ISUPinRDNIS redirection / Redirecting Number */
	private String redRedirectingNumber;

	/**
	 * ISUPinRDNIS redirection / Redirecting Number Nature of Address Indicator
	 */
	private Short redRedirectingNumberNadi;

	/**
	 * ISUPinRDNIS redirection / Redirecting Number Number Plan
	 */
	private Short redRedirectingNumberNumberPlan;

	/** ISUPinRDNIS redirection / Original Called Number */
	private String redOriginalCalledNumber;

	/**
	 * ISUPinRDNIS redirection / Redirecting Indicator
	 */
	private Short redRedirectingIndicator;

	/**
	 * ISUPinRDNIS redirection / Original Redirecting Reason
	 */
	private Short redOriginalRedirectingReason;

	/**
	 * ISUPinRDNIS redirection / Original Redirecting Reason
	 */
	private Short redRedirectingReason;

	/**
	 * ISUPinRDNIS redirection / Redirection Counter
	 */
	private Short redRedirectionCounter;

	/**
	 * ISUPinRDNIS redirection / Reserve National
	 */
	private Short redReserveNational;

	/** ISUPinRNIS IAM */
	private String iam;

	public String getIam() {
		return iam;
	}

	public void setIam(String iam) {
		this.iam = iam;
	}

	public Short getCalledNadi() {
		return calledNadi;
	}

	public Short getCallingNadi() {
		return callingNadi;
	}

	public void setCalledNadi(Short calledNadi) {
		this.calledNadi = calledNadi;
	}

	public void setCallingNadi(Short callingNadi) {
		this.callingNadi = callingNadi;
	}

	public Short getCallingScreen() {
		return callingScreen;
	}

	public void setCallingScreen(Short callingScreen) {
		this.callingScreen = callingScreen;
	}

	public Short getCallingPres() {
		return callingPres;
	}

	public void setCallingPres(Short callingPres) {
		this.callingPres = callingPres;
	}

    public void setCallingUsedType(String type) {
        this.callingUsedType = type;
    }

    public String getCallingUsedType() {
        return callingUsedType;
    }

	public Short getGenNadi() {
		return genNadi;
	}

	public void setGenNadi(Short genNadi) {
		this.genNadi = genNadi;
	}

	public Short getRedRedirectingIndicator() {
		return redRedirectingIndicator;
	}

	public void setRedRedirectingIndicator(Short redRedirectingIndicator) {
		this.redRedirectingIndicator = redRedirectingIndicator;
	}

	public Short getRedOriginalRedirectingReason() {
		return redOriginalRedirectingReason;
	}

	public void setRedOriginalRedirectingReason(
			Short redOriginalRedirectingReason) {
		this.redOriginalRedirectingReason = redOriginalRedirectingReason;
	}

	public Short getRedRedirectingReason() {
		return redRedirectingReason;
	}

	public void setRedRedirectingReason(Short redRedirectingReason) {
		this.redRedirectingReason = redRedirectingReason;
	}

	public Short getRedRedirectionCounter() {
		return redRedirectionCounter;
	}

	public void setRedRedirectionCounter(Short redRedirectionCounter) {
		this.redRedirectionCounter = redRedirectionCounter;
	}

	public Short getRedReserveNational() {
		return redReserveNational;
	}

	public void setRedReserveNational(Short redReserveNational) {
		this.redReserveNational = redReserveNational;
	}

	public String getRedOriginalCalledNumber() {
		return redOriginalCalledNumber;
	}

	public void setRedOriginalCalledNumber(
			String redRedirectingOriginalCalledNumber) {
		this.redOriginalCalledNumber = redRedirectingOriginalCalledNumber;
	}

	public Short getRedRedirectingNumberNumberPlan() {
		return redRedirectingNumberNumberPlan;
	}

	public void setRedRedirectingNumberNumberPlan(
			Short redRedirectingNumberNumberPlan) {
		this.redRedirectingNumberNumberPlan = redRedirectingNumberNumberPlan;
	}

	public Short getRedRedirectingNumberNadi() {
		return redRedirectingNumberNadi;
	}

	public void setRedRedirectingNumberNadi(Short redRedirectingNumberNadi) {
		this.redRedirectingNumberNadi = redRedirectingNumberNadi;
	}

	public Short getRedRedirectingNumberPresentation() {
		return redRedirectingNumberPresentation;
	}

	public void setRedRedirectingNumberPresentation(
			Short redRedirectingNumberPresentation) {
		this.redRedirectingNumberPresentation = redRedirectingNumberPresentation;
	}

    /** ISUPinRDNIS redrirection / Redirecting Number Presentation */
    private Short redRedirectingNumberPresentation;

    public String getRedRedirectingNumber() {
        return redRedirectingNumber;
    }

    public void setRedRedirectingNumber(String redRedirectingNumber) {
        this.redRedirectingNumber = redRedirectingNumber;
    }

    public void encode(AgiChannel channel) throws AgiException { 
        sipAddHeader(channel, XF_CPC, getCallingPartyIndicator()); // unused by smg but by me for redirection & porta (TODO)

        sipAddHeader(channel, XF_CLG_PRES, getCallingPres().toString());
        sipAddHeader(channel, XF_CLG_SCREEN, getCallingScreen().toString());
        sipAddHeader(channel, XF_CLG_NADI, getCallingNadi().toString());

        if (getGenNumberQualifierIndicator() != null) {
            sipAddHeader(channel, XF_GN_NUMQUAL, getGenNumberQualifierIndicator().toString());
            sipAddHeader(channel, XF_GN, getGenNumber());
            sipAddHeader(channel, XF_GN_NADI, getGenNadi().toString());
            sipAddHeader(channel, XF_GN_SCREEN, getGenAddressScreeningIndicator().toString());
            sipAddHeader(channel, XF_GN_PRES, getGenAddressPresentationIndicator().toString());
            sipAddHeader(channel, XF_GN_PLAN, getGenNumberPlanIndicator().toString());
        }

		if (getRedRedirectingNumber() != null) {
      sipAddHeader(channel, XF_RDNIS, getRedRedirectingNumber());
			sipAddHeader(channel, XF_RDNIS_NADI, getRedRedirectingNumberNadi().toString());
			sipAddHeader(channel, XF_RDNIS_PRES, getRedRedirectingNumberPresentation().toString());
			sipAddHeader(channel, XF_RDNIS_PLAN, getRedRedirectingNumberNumberPlan().toString());
			//sipAddHeader(channel, XF_RDNIS_ORIG, getRedOriginalCalledNumber()); // TODO SMG !?!?
			sipAddHeader(channel, XF_RDINF_INDICATOR, getRedRedirectingIndicator().toString());
			sipAddHeader(channel, XF_RDINF_ORIG_REASON, getRedOriginalRedirectingReason().toString());
			sipAddHeader(channel, XF_RDINF_REASON, getRedRedirectingReason().toString());
			sipAddHeader(channel, XF_RDINF_COUNT, getRedRedirectionCounter().toString());
			//sipAddHeader(channel, XF_RDINF_RES, getRedReserveNational()); // TODO SMG
        }
        // unusable
        //if(getIam() != null) {
        //  sipAddHeader(channel, XF_IAM, getIam());
        //}
    }

    public static String getSipHeader(AgiChannel channel, String key) throws AgiException {
        return channel.getVariable("SIP_HEADER(" + key + ")");
    }

    public static void sipAddHeader(AgiChannel channel, String key, String value) throws AgiException {
        channel.exec("SipAddHeader", key + ": " + value);
    }

	public String getCallingPartyIndicator() {
		return callingPartyIndicator;
	}

	public Short getGenAddressPresentationIndicator() {
		return genAddressPresentationIndicator;
	}

	public Short getGenAddressScreeningIndicator() {
		return genAddressScreeningIndicator;
	}

	public Short getGenNumberPlanIndicator() {
		return genNumberPlanIndicator;
	}

	public Short getGenNumberQualifierIndicator() {
		return genNumberQualifierIndicator;
	}

	public String getGenNumber() {
		return genNumber;
	}

	public void setCallingPartyIndicator(String cpc) {
		this.callingPartyIndicator = cpc;
	}

	public void setGenAddressPresentationIndicator(
			Short genAddressPresentationIndicator) {
		this.genAddressPresentationIndicator = genAddressPresentationIndicator;
	}

	public void setGenAddressScreeningIndicator(
			Short genAddressScreeningIndicator) {
		this.genAddressScreeningIndicator = genAddressScreeningIndicator;
	}

	public void setGenNumberPlanIndicator(Short genNumberPlanIndicator) {
		this.genNumberPlanIndicator = genNumberPlanIndicator;
	}

	public void setGenNumberQualifierIndicator(Short genNumberQualifierIndicator) {
		this.genNumberQualifierIndicator = genNumberQualifierIndicator;
	}

	public void setGenNumber(String genNumber) {
		this.genNumber = genNumber;
	}

	@Override
	public String toString() {
		return ToStringBuilder.reflectionToString(this,
				ToStringStyle.MULTI_LINE_STYLE);
	}

	public IsupInRdnis(String cpc, Short calledNadi, Short callingNadi, Short callingPres) {
		setCallingPartyIndicator(cpc);
        setCalledNadi(calledNadi);
        setCallingNadi(callingNadi);
        setCallingPres(callingPres);
	}

	public IsupInRdnis(String cpc) {
		setCallingPartyIndicator(cpc);
	}

	private IsupInRdnis() {
	    // empty
	}

	public static IsupInRdnis decode(AgiChannel channel) throws AgiException {
		IsupInRdnis isup = new IsupInRdnis();

        checkRndisCpc(getSipHeader(channel, XF_CPC), isup);

        isup.setCalledNadi(parseShort(getSipHeader(channel, XF_CLD_NADI), 0, 255,
                    "Calling number / Nature of Address Indicator"));

        isup.setCallingNadi(parseShort(getSipHeader(channel, XF_CLG_NADI), 0, 255,
                    "Calling number / Nature of Address Indicator"));

        isup.setCallingScreen(parseShort(getSipHeader(channel, XF_CLG_SCREEN), 0, 255,
                    "Calling number / Screen indicator"));

        isup.setCallingPres(parseShort(getSipHeader(channel, XF_CLG_PRES), 0, 255,
                    "Calling number / Presentation"));

        if(getSipHeader(channel, XF_GN) != null) {
            try {
                parseRndisGen(channel, isup);
            } catch (IllegalArgumentException e) {
                log.warn("Generic number is invalid : " + e.getMessage());
            }
        }
        // RED
        if(getSipHeader(channel, XF_RDNIS) != null) {
            try {
                parseRndisRed(channel, isup);
            } catch (IllegalArgumentException e) {
                log.warn("RDNIS is invalid : " + e.getMessage());
            }
        }
        // unusable
        //// IAM
        //if(getSipHeader(channel, XF_IAM) != null) {
        //  isup.setIam(getSipHeader(channel, XF_IAM));
        //}

        return isup;
    }

    private static void checkRndisCpc(String cpc, IsupInRdnis isup) {
        Matcher matcher = CPC_PATTERN.matcher(cpc);
        if (!matcher.matches()) {
            throw new IllegalArgumentException(
                    "Unrecognized RDNIS, no CPC found but: '" + cpc + "'");
        }
        isup.setCallingPartyIndicator(cpc);
    }

    private static Short parseShort(String shortStr, int i, int j, String name) {
        if (shortStr == null) throw new IllegalArgumentException(name + " does not exists");
        Short value = Short.valueOf(shortStr);
        if (value < 0 || value > 255) {
            throw new IllegalArgumentException(name
                    + " should be in range 000..255");
        }
        return value;
    }

    private static void parseRndisGen(AgiChannel channel, IsupInRdnis isup)
        throws AgiException {
        String num;
        Short numQual = null;
        Short genNadi = null;
        Short genScreen = null;
        Short genPres = null;
        Short genPlan = null;

        numQual = parseShort(getSipHeader(channel, XF_GN_NUMQUAL), 0,
                255, "Generic number / Number Qualifier Indicator");
        num = getSipHeader(channel, XF_GN);
        if (num.length() == 0 || num.length() > 31) {
            throw new IllegalArgumentException(
                    "Generic number / Number should be of size 1..31");
        }
        genNadi = parseShort(getSipHeader(channel, XF_GN_NADI), 0, 255,
                "Generic number / Nature of Address Indicator");
        genScreen = parseShort(getSipHeader(channel, XF_GN_SCREEN), 0, 3,
                "Generic number / Address Screening Indicator");
        genPres = parseShort(getSipHeader(channel, XF_GN_PRES), 0,
                3, "Generic number / Address Presentation Indicators");
        genPlan = parseShort(getSipHeader(channel, XF_GN_PLAN), 0, 7,
                "Generic number / Number Plan Indicator");

        isup.setGenNumberQualifierIndicator(numQual);
        isup.setGenNumber(num);
        isup.setGenNadi(genNadi);
        isup.setGenAddressScreeningIndicator(genScreen);
        isup.setGenAddressPresentationIndicator(genPres);
        isup.setGenNumberPlanIndicator(genPlan);
    }

    private static void parseRndisRed(AgiChannel channel, IsupInRdnis isup) throws AgiException {
        String num;
        Short rdnisNadi = null;
        Short rdnisPres = null;
        Short rdnisPlan = null;
        Short rdinfIndicator = null;
        Short rdinfOrigReason = null;
        Short rdinfReason = null;
        Short rdinfCount = null;
        Short rdinfRes = null;

        num = getSipHeader(channel, XF_RDNIS);
        if (num.length() == 0 || num.length() > 31) {
            throw new IllegalArgumentException(
                    "Redirection / Number should be of size 0..31");
        }
        rdnisNadi = parseShort(getSipHeader(channel, XF_RDNIS_NADI), 0, 255,
                "Redirection / Redirecting Number "
                + "Nature of Address Indicator");
        rdnisPres = parseShort(getSipHeader(channel, XF_RDNIS_PRES), 0,
                3, "Redirection / Redirecting Number Presentation");
        rdnisPlan = parseShort(getSipHeader(channel, XF_RDNIS_PLAN), 0,
                7, "Redirection / Redirecting Number Number Plan");
        rdinfIndicator = parseShort(getSipHeader(channel, XF_RDINF_INDICATOR), 0, 7,
                "Redirection / Redirecting Indicator");
        rdinfOrigReason = parseShort(getSipHeader(channel, XF_RDINF_ORIG_REASON), 0, 15,
                "Redirection / Original Redirecting Reason");
        rdinfReason = parseShort(getSipHeader(channel, XF_RDINF_REASON), 0, 15,
                "Redirection / Redirecting Reason");
        rdinfCount = parseShort(getSipHeader(channel, XF_RDINF_COUNT), 0, 5,
                    "Redirection / Redirection Counter");
        //rdinfRes = parseShort(getSipHeader(channel, XF_RDINF_RES, 0, 1,
        //      "Redirection / Reserve National")
        //num = getSipHeader(channel, XF_RDNIS_ORIG);
        //if (num.length() == 0 || num.length() > 31) {
        //  throw new IllegalArgumentException(
        //      "Redirection / Number should be of size 0..31");
        //}

        isup.setRedRedirectingNumber(num);
        isup.setRedRedirectingNumberNadi(rdnisNadi);
        isup.setRedRedirectingNumberPresentation(rdnisPres);
        isup.setRedRedirectingNumberNumberPlan(rdnisPlan);
        //isup.setRedOriginalCalledNumber(elts[eltNb]);
        isup.setRedRedirectingIndicator(rdinfIndicator);
        isup.setRedOriginalRedirectingReason(rdinfOrigReason);
        isup.setRedRedirectingReason(rdinfReason);
        isup.setRedRedirectionCounter(rdinfCount);
        //isup.setRedReserveNational(rdinfRes);
    }

    public boolean genValid() {
        return (getGenNadi() == 4 || (getGenNadi() == 3 && getGenNumber().length() == 9));
    }
}
