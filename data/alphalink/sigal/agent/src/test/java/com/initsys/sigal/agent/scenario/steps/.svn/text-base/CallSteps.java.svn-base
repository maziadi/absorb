package com.initsys.sigal.agent.scenario.steps;

import static org.easymock.classextension.EasyMock.eq;
import static org.easymock.classextension.EasyMock.expect;
import static org.easymock.classextension.EasyMock.matches;

import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.Locale;
import java.util.Date;
import java.util.concurrent.TimeoutException;
import java.util.Random;

import org.apache.commons.lang.BooleanUtils;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;
import org.asteriskjava.live.HangupCause;
import org.easymock.classextension.EasyMock;
import org.easymock.IMocksControl;
import org.jbehave.scenario.annotations.Given;
import org.jbehave.scenario.annotations.Named;
import org.jbehave.scenario.annotations.Then;
import org.jbehave.scenario.annotations.When;
import org.jbehave.scenario.steps.Steps;

import com.initsys.sigal.agent.SigalAgentTemplate;
import com.initsys.sigal.agent.SiAgentTemplate;
import com.initsys.sigal.agent.agi.AbstractSigalAgi;
import com.initsys.sigal.agent.agi.mrf5.Mrf5OutboundAgi;
import com.initsys.sigal.agent.agi.mrf5.Mrf5InboundAgi;
import com.initsys.sigal.agent.agi.mrf5.SviRioAgi;
import com.initsys.sigal.agent.agi.ss7.AbstractFtAgi;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.MlidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.EmdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.NpdbQueryResponse;
import com.initsys.sigal.protocol.Si.SviRioQueryResponse;
import com.initsys.sigal.protocol.Si.SviRioQueryRequest;
import com.initsys.sigal.protocol.Sigal.ResponseStatus;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;
import com.initsys.sigal.protocol.Si.SmsSendRequest;
import com.initsys.sigal.protocol.Si.SmsServerAck;
import com.initsys.sigal.protocol.Si.SmsData;
import com.google.protobuf.Message;
import com.initsys.sigal.vno.VnoConstants;

public class CallSteps extends Steps {

    /** logger */
    static final Logger log = LoggerFactory.getLogger(CallSteps.class);

    private static final String TEST_NODE_NAME = "testNode";

    public static String AGI_PACKAGE_PREFIX = "com.initsys.sigal.agent.agi";

    public static final ResponseStatus OK_STATUS = ResponseStatus.newBuilder()
            .setCode(ResponseStatusCode.OK).build();

    public static final ResponseStatus NOT_FOUND_STATUS = ResponseStatus
            .newBuilder().setCode(ResponseStatusCode.NOT_FOUND).build();

    private AbstractSigalAgi agi;

    private AgiChannel channel;

    private SigalAgentTemplate template;

    private SiAgentTemplate siTemplate;

    private AgiRequest request;

    private String icid;

    private Random random;

    private IMocksControl mockCtrl;

    public IMocksControl getMockCtrl() {
        return mockCtrl;
    }

    public void setMockCtrl(IMocksControl mockCtrl) {
        this.mockCtrl = mockCtrl;
    }

    public String getIcid() {
        return icid;
    }

    public void setIcid(String icid) {
        this.icid = icid;
    }

    public Random getRandom() {
        return random;
    }

    public void setRandom(Random random) {
        this.random = random;
    }

    @When("redirecting from $number")
    public void expectVariableRedirectFrom(String number) throws AgiException {
        expect(channel.getVariable(VnoConstants.REDIRECTED_FROM))
                .andStubReturn(normalize(number));
    }

    @Given("$class and outbound_timeout: $timeout, gw_channel_name: $gwChannelName")
    public void outboundAgi(String klass, int timeout, List<String> gwChannelName)
            throws InstantiationException, IllegalAccessException {
        instanciateAgi(klass);
        getAgi().setOutEstablishmentTimeout(timeout);
        String[] gw = gwChannelName.toArray(new String[gwChannelName.size()]);
        getAgi().setGwChannelName(gw);
        if (getAgi() instanceof Mrf5OutboundAgi) {
            String[] inboundGw = new String[gw.length];
            for (int i = 0; i < inboundGw.length; i++) inboundGw[i] = gw[i] + "-in";
            ((Mrf5OutboundAgi) getAgi()).setInboundGwChannelName(inboundGw);
        }
        getAgi().setNodeName(TEST_NODE_NAME);
    }

    @Given("$class and inbound_timeout: $timeout, gw_channel_name: $gwChannelName, emergency_numbers: $emergency_numbers")
    public void inboundAgiMrf5(String klass, int timeout, List<String> gwChannelName, List<String> emergencyNumbers)
            throws InstantiationException, IllegalAccessException,
            ClassNotFoundException {
        instanciateAgi(klass);
        getAgi().setInEstablishmentTimeout(timeout);
        String[] gw = gwChannelName.toArray(new String[gwChannelName.size()]);
        getAgi().setGwChannelName(gw);
        getAgi().setNodeName(TEST_NODE_NAME);
        String[] em = emergencyNumbers.toArray(new String[emergencyNumbers.size()]);
        ((Mrf5InboundAgi) getAgi()).setEmergencyNumbers(em);
    }

    @Given("$class and inbound_timeout: $timeout, gw_channel_name: $gwChannelName")
    public void inboundAgi(String klass, int timeout, List<String> gwChannelName)
            throws InstantiationException, IllegalAccessException,
            ClassNotFoundException {
        instanciateAgi(klass);
        getAgi().setInEstablishmentTimeout(timeout);
        String[] gw = gwChannelName.toArray(new String[gwChannelName.size()]);
        getAgi().setGwChannelName(gw);
        getAgi().setNodeName(TEST_NODE_NAME);
    }

    @Given("$class and gw_channel_name: $gwChannelName")
    public void sviRioAgi(String klass, List<String> gwChannelName)
            throws InstantiationException, IllegalAccessException,
            ClassNotFoundException {
        instanciateAgi(klass);
        String[] gw = gwChannelName.toArray(new String[gwChannelName.size()]);
        getAgi().setGwChannelName(gw);
        getAgi().setNodeName(TEST_NODE_NAME);
    }

    private void instanciateAgi(String klass) throws InstantiationException,
            IllegalAccessException {
        System.err.println("Test class: " + AGI_PACKAGE_PREFIX + "." + klass);
        try {
            setAgi((AbstractSigalAgi) Thread.currentThread()
                    .getContextClassLoader().loadClass(
                            AGI_PACKAGE_PREFIX + "." + klass).newInstance());
        } catch (NoClassDefFoundError e) {
            e.printStackTrace();
            throw new RuntimeException(String.format(
                    "No class def found: '%s'", AGI_PACKAGE_PREFIX + "."
                            + klass), e);
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            throw new RuntimeException(String.format(
                    "Unable to find class: '%s'", AGI_PACKAGE_PREFIX + "."
                            + klass));
        }
        System.err.println("Test class loaded.");
    }

    @Given("$class and inbound_timeout: $timeout, outbound_timeout: $out_timeout, ft_chan: $ftName, op_chan: $op_chan, nsg_chan: $nsg_chan, gw_chan: $gw_chan")
    public void inboundAgiFt(String klass, int inbound_timeout,
            int outbound_timeout, String ftChannelName, String opChannelName,
            String nsgChannelName, List<String> gwChannelName) throws InstantiationException,
            IllegalAccessException {
        instanciateAgi(klass);
        getAgi().setInEstablishmentTimeout(inbound_timeout);
        getAgi().setOutEstablishmentTimeout(outbound_timeout);
        String[] gw = gwChannelName.toArray(new String[gwChannelName.size()]);
        getAgi().setGwChannelName(gw);
        getAgi().setNodeName(TEST_NODE_NAME);
        ((AbstractFtAgi) getAgi()).setFtChannelName(ftChannelName);
        ((AbstractFtAgi) getAgi()).setOpChannelName(opChannelName);
        ((AbstractFtAgi) getAgi()).setNsgChannelName(nsgChannelName);
    }

    @Deprecated
    @Given("remote party ID $number $privacy")
    public void aRemotePartyId(String number, String privacy)
            throws AgiException {

        expectGetSipHeader("Remote-Party-ID", "Remote-Party-ID: \"" + number
                + "\" <sip:" + number + "@217.15.88.253>;privacy=" + privacy
                + ";screen=yes");
    }

    @Given("icid $icid")
    public void icid(String icid) throws AgiException {
        setIcid(icid);
        expectGetSipHeader("P-Charging-Vector",
                "P-Charging-Vector: icid-value=" + icid
                        + "; icid-generated-at=" + TEST_NODE_NAME);
    }

    @Given("SIP DOMAIN $domain")
    public void sipUri(String sipDomain) throws AgiException {
        expectGetFullVariable("SIPDOMAIN", sipDomain);
    }

    @Given("a call from $callerName <$callerNumber> to $calledNumber within $carrierCode")
    public void aCall(@Named("callerName") String callerName,
            @Named("callerNumber") String callingNumber,
            @Named("calledNumber") String calledNumber,
            @Named("carrierCode") String carrierCode) throws AgiException,
            InstantiationException, IllegalAccessException,
            ClassNotFoundException {

        setMockCtrl(EasyMock.createStrictControl());

        setRequest(mockCtrl.createMock(AgiRequest.class));
        setChannel(mockCtrl.createMock(AgiChannel.class));
        setTemplate(mockCtrl.createMock(SigalAgentTemplate.class));
        getAgi().setTemplate(getTemplate());

        expect(getRequest().getCallerIdName()).andStubReturn(callerName);
        expect(getRequest().getExtension()).andStubReturn(calledNumber);
        expect(getRequest().getChannel()).andStubReturn("SIP/xyzetodo");
        expect(getRequest().getDnid()).andStubReturn("TODO");
        expect(getRequest().getRdnis()).andStubReturn("");
        expect(getRequest().getCallerIdNumber()).andStubReturn(callingNumber);
        expectGetSipHeader("X-RedirectingNumber", "");
        expectGetFullVariable("CALLERID(num)", callingNumber);
        expectGetSipHeader("X-CarrierCode", normalize(carrierCode));

        Random randomClass = getMockCtrl().createMock(Random.class);
        setRandom(randomClass);
        getAgi().setRandom(randomClass);
    }

    @Given("a call from $callerName <$callerNumber> to $calledNumber")
    public void bCall(String callerName, String callerNumber,
            String calledNumber) throws AgiException, InstantiationException,
            IllegalAccessException, ClassNotFoundException {
        aCall(callerName, callerNumber, calledNumber, null);
    }

    @Given("a call to svi rio from $callerName <$callerNumber> to $calledNumber within $carrierCode")
    public void aCallToSviRio(String callerName, String callerNumber,
            String calledNumber, String carrierCode)
            throws AgiException, InstantiationException,
            IllegalAccessException, ClassNotFoundException {
        aCall(callerName, callerNumber, calledNumber, carrierCode);
        setSiTemplate(mockCtrl.createMock(SiAgentTemplate.class));
        ((SviRioAgi) getAgi()).setSviRioTemplate(getSiTemplate());
    }

    @Then("query NPDB by $number returning $prefix")
    public void queryNpdb(String number, String prefix) throws TimeoutException {
        NpdbQueryResponse.Builder response = NpdbQueryResponse.newBuilder()
                .setVersion(1).setNumber(number);

        if (prefix != null) {
            response.setPrefix(prefix);
        }
        expect(getTemplate().queryPorted(number)).andReturn(response.build());
    }

    @Then("query NPDB by $number and find nothing")
    public void queryNpdbFindNothing(String number) throws TimeoutException {
        NpdbQueryResponse.Builder response = NpdbQueryResponse.newBuilder()
                .setVersion(1).setNumber(number).setStatus(NOT_FOUND_STATUS);

        expect(getTemplate().queryPorted(number)).andReturn(response.build());
    }

    @Then("query LIDB by account_code with $account_code returning $options")
    public void queryLidbByAccountCode(String accountCode, String optionsString)
            throws TimeoutException {
        Map<String, String> options = parseOptions(optionsString);
        log.debug("Options are: " + options);

        LidbQueryResponse.Builder response = LidbQueryResponse.newBuilder()
                .setVersion(1).setAccountCode(accountCode)
                .setStatus(OK_STATUS);

        if (options.containsKey("subscriber_number")) {
            response.setSubscriberNumber(options.get("subscriber_number"));
        }
        if (options.containsKey("out_plan")) {
            response.setOutboundNumberingPlan(options.get("out_plan"));
        }
        if (options.containsKey("in_plan")) {
            response.setInboundNumberingPlan(options.get("in_plan"));
        }
        if (options.containsKey("carrier_code")) {
            response.setCarrierCode(options.get("carrier_code"));
        }
        if (options.containsKey("max_calls")) {
            response.setMaxCalls(Integer.parseInt(options.get("max_calls")));
        }
        if (options.containsKey("call_count")) {
            response.setCallCount(Integer.parseInt(options.get("call_count")));
        }
        if (options.containsKey("voicemail")) {
            response.setVoicemail(Integer.parseInt(options.get("voicemail")));
        }
        if (options.containsKey("trunk")) {
            response.setTrunk(options.get("trunk").equals("true"));
        }
        if (options.containsKey("indication")) {
            response.setIndication(options.get("indication").equals("true"));
        }
        if (options.containsKey("locked")) {
            response.setLocked(options.get("locked").equals("true"));
        }
        if (options.containsKey("fixed_cid")) {
            response.setFixedCid(options.get("fixed_cid").equals("true"));
        }
        if (options.containsKey("insee_code")) {
            response.setInseeCode(options.get("insee_code"));
        }

        expectQueryLineInfoByAccountCode(accountCode,
                response);
    }

    @Then("query LIDB with $number and return $options")
    public void queryLidb(String number, String optionsString)
            throws TimeoutException {
        Map<String, String> options = parseOptions(optionsString);
        log.debug("Options are: " + options);

        LidbQueryResponse.Builder response = LidbQueryResponse.newBuilder()
                .setVersion(1).setNumber(number)
                .setStatus(OK_STATUS);

        if (options.containsKey("subscriber_number")) {
            response.setSubscriberNumber(options.get("subscriber_number"));
        }
        if (options.containsKey("redirect_to")) {
            response.setRedirectTo(options.get("redirect_to"));
        }
        if (options.containsKey("out_plan")) {
            response.setOutboundNumberingPlan(options.get("out_plan"));
        }
        if (options.containsKey("in_plan")) {
            response.setInboundNumberingPlan(options.get("in_plan"));
        }
        if (options.containsKey("account_code")) {
            response.setAccountCode(options.get("account_code"));
        }
        if (options.containsKey("carrier_code")) {
            response.setCarrierCode(options.get("carrier_code"));
        }
        if (options.containsKey("voicemail")) {
            response.setVoicemail(Integer.parseInt(options.get("voicemail")));
        }
        if (options.containsKey("insee_code")) {
            response.setInseeCode(options.get("insee_code"));
        }
        if (options.containsKey("trunk")) {
            response.setTrunk(options.get("trunk").equals("true"));
        }
        if (options.containsKey("fixed_cid")) {
            response.setFixedCid(options.get("fixed_cid").equals("true"));
        }
        expectQueryLineInfo(number,
                response);
    }

    @Then("query MLIDB with $msisdn and return $options")
    public void queryMobileLineInfoByMsisdn(String msisdn, String optionsString)
            throws TimeoutException {
        Map<String, String> options = parseOptions(optionsString);
        log.debug("Options are: " + options);

        MlidbQueryResponse.Builder response = MlidbQueryResponse.newBuilder()
                .setVersion(1).setMsisdn(msisdn)
                .setStatus(OK_STATUS);

        if (options.containsKey("msisdn")) {
            response.setMsisdn(options.get("msisdn"));
        }
        if (options.containsKey("account_code")) {
            response.setAccountCode(options.get("account_code"));
        }
        if (options.containsKey("carrier_code")) {
            response.setCarrierCode(options.get("carrier_code"));
        }
        if (options.containsKey("max_vno_calls")) {
            response.setMaxVnoCalls(Integer.parseInt(options.get("max_vno_calls")));
        }
        if (options.containsKey("vno_call_count")) {
            response.setVnoCallCount(Integer.parseInt(options.get("vno_call_count")));
        }

        expect(getTemplate().queryMobileLineInfoByMsisdn(msisdn)).andReturn(
                 response.build());
     }

    @Then("query MLIDB with $msisdn and find nothing")
    public void queryMobileLineInfoAndFindNothing(String msisdn)
            throws TimeoutException {
        MlidbQueryResponse.Builder response = MlidbQueryResponse.newBuilder()
                .setVersion(1).setMsisdn(msisdn)
                .setStatus(NOT_FOUND_STATUS);

        expect(getTemplate().queryMobileLineInfoByMsisdn(msisdn)).andReturn(
                 response.build());
     }

    @Then("query EXDB with $accountCode returning $options")
    public void queryExdbByAccountCode(String accountCode, String optionsString)
            throws TimeoutException {
        Map<String, String> options = parseOptions(optionsString);
        log.debug("Options are: " + options);

        ExdbQueryResponse.Builder response = ExdbQueryResponse.newBuilder()
                .setVersion(1).setAccountCode(accountCode)
                .setStatus(OK_STATUS);

        if (options.containsKey("subscriber_number")) {
            response.setSubscriberNumber(options.get("subscriber_number"));
        }
        if (options.containsKey("out_plan")) {
            response.setOutboundNumberingPlan(options.get("out_plan"));
        }
        if (options.containsKey("in_plan")) {
            response.setInboundNumberingPlan(options.get("in_plan"));
        }
        if (options.containsKey("carrier_code")) {
            response.setCarrierCode(options.get("carrier_code"));
        }
        if (options.containsKey("max_calls")) {
            response.setMaxCalls(Integer.parseInt(options.get("max_calls")));
        }
        if (options.containsKey("call_count")) {
            response.setCallCount(Integer.parseInt(options.get("call_count")));
        }

        if (options.containsKey("weird_identity")) {
            response.setWeirdIdentity(options.get("weird_identity").equals("true"));
        }

        if (options.containsKey("locked")) {
            response.setLocked(options.get("locked").equals("true"));
        }

        expect(getTemplate().queryIntercoByAccountCode(accountCode)).andReturn(
                 response.build());
     }

    @Then("query EXDB with $accountCode and find nothing")
    public void queryExdbByAccountCodeAndFindNothing(String accountCode)
            throws TimeoutException {
        ExdbQueryResponse.Builder response = ExdbQueryResponse.newBuilder()
                .setVersion(1).setAccountCode(accountCode)
                .setStatus(NOT_FOUND_STATUS);

        expect(getTemplate().queryIntercoByAccountCode(accountCode)).andReturn(
                 response.build());
     }

    @Then("query LIDB by account_code with $accountCode and find nothing")
    public void queryLidbByAccountCodeAndReturnNotFound(String accountCode)
            throws TimeoutException {
        LidbQueryResponse.Builder response = LidbQueryResponse.newBuilder()
                .setVersion(1).setAccountCode(accountCode).setStatus(NOT_FOUND_STATUS);
        expectQueryLineInfoByAccountCode(accountCode, response);
    }

    @Then("query LIDB with $number and find nothing")
    public void queryLidbAndReturnNotFound(String number)
            throws TimeoutException {
        LidbQueryResponse.Builder response = LidbQueryResponse.newBuilder()
                .setVersion(1).setNumber(number).setStatus(NOT_FOUND_STATUS);
        expectQueryLineInfo(number, response);
    }

    @Then("query EMDB with $number/$insee_code and return $translations")
    public void queryEmdb(String number, String inseeCode, List<String> translations)
            throws TimeoutException {
        EmdbQueryResponse.Builder response = EmdbQueryResponse.newBuilder()
                .setVersion(1).setNumber(number).setInseeCode(inseeCode)
                .setStatus(OK_STATUS);
        response.addAllTranslation(translations);
        expect(getTemplate().queryEmergency(number, inseeCode)).andReturn(
                response.build());
    }

    private void expectQueryLineInfo(String number,
            LidbQueryResponse.Builder response) throws TimeoutException {
        expect(getTemplate().queryLineInfoByNumber(number)).andReturn(
                response.build());
    }

    private void expectQueryLineInfoByAccountCode(String accountCode,
            LidbQueryResponse.Builder response) throws TimeoutException {
        expect(getTemplate().queryLineInfoByAccountCode(accountCode))
                .andReturn(response.build());
    }

    @Then("query SviRio with $number returning msisdn: $msisdn, rio: $rio, date: $date")
    public void querySviRioByNumber(String number, String msisdn, String rio, String date)
            throws TimeoutException {
        SviRioQueryResponse.Builder response = SviRioQueryResponse.newBuilder();

        response.setMsisdn(msisdn);
        response.setRio(rio);
        if (!StringUtils.isBlank(normalize(date))) {
            response.setDate(date);
        }
        expect(getSiTemplate().querySviRioByNumber(number)).andReturn(
                 response.build());
    }

    @Then("query SviRio with $number and find nothing")
    public void querySviRioByNumberFindNoting(String number)
            throws TimeoutException {
        SviRioQueryResponse.Builder response = SviRioQueryResponse.newBuilder();

        expect(getSiTemplate().querySviRioByNumber(number)).andReturn(
                 response.build());
    }

    @Then("query SviRio with $number and get timeout")
    public void querySviRioByNumberTimeout(String number)
            throws TimeoutException {
        expect(getSiTemplate().querySviRioByNumber(number))
            .andThrow(new TimeoutException("Test TimeoutException"));
    }

    @Then("query SviRio with $number and get exception")
    public void querySviRioByNumberException(String number)
            throws TimeoutException {
        expect(getSiTemplate().querySviRioByNumber(number))
            .andThrow(new RuntimeException("Test RuntimeException"));
    }

    @Then("set callerId to $callerIdNum and $callerIdName")
    public void setCallerId(@Named("callerIdNum") String number,
            @Named("callerIdName") String name) throws AgiException {
        if ("''".equals(name)) {
            name = "";
        }
        expect(getChannel().exec("Set", "CALLERID(num)=" + number))
                .andReturn(0);
        expect(getChannel().exec("Set", "CALLERID(name)=" + name)).andReturn(0);
    }

    @Then("redirect from $number to $redirectNumber")
    public void expectRedirect(String number, String redirectNumber)
            throws AgiException {
        channel.setVariable(VnoConstants.REDIRECTED_FROM, number);
        expect(getChannel().exec("Goto", redirectNumber + ",1")).andReturn(0);
    }

    @Then("set callerIdNum to $number")
    public void setCallerId(String number) throws AgiException {
        expect(getChannel().exec("Set", "CALLERID(num)=" + number))
                .andReturn(0);
    }

    //TODO 1.9.1 ne doit etre utilise que par Isdn
    @Deprecated
    @Then("set caller presentation to $pres")
    public void setCallerPresentation(String pres) throws AgiException {
        expect(getChannel().exec("Set", "CALLERID(num-pres)=" + pres)).andReturn(0);
    }

    @Then("dial channel $channelName with nadi $nadi, number $number and options $options")
    public void dialFt(String channelName, String nadi, String number,
            int options) throws AgiException {

        //expect(getChannel().exec("SetTransferCapability", "3K1AUDIO"))
        //        .andReturn(0); // TODO SMG

        setHeader("X-FreeTDM-CLD-NADI", nadi);
        expect(
                getChannel().exec("Dial",
                        channelName + "/" + number + "," + options))
                .andReturn(0);
    }

    @Then("dial announce $channel with prefix $prefix, number $number, timeout $timeout and separator $sep")
    public void dialIndication(String channelName, String prefix, String number,
            int timeout, String sep) throws AgiException {
        dialChannel(channelName, prefix + number, timeout, sep, null);
    }

    @Then("dial channel $channel with number $number, timeout $timeout and separator $sep g")
    public void dialChannelG(String channelName, String number, int timeout,
            String sep) throws AgiException {
        dialChannel(channelName, number, timeout, sep, "g");
    }

    @Then("dial channel $channel with number $number, timeout $timeout and separator $sep")
    public void dialChannel(String channelName, String number, int timeout,
            String sep) throws AgiException {
        dialChannel(channelName, number, timeout, sep, null);
    }

    public void dialChannel(String channelName, String number, int timeout,
            String sep, String extraOptions) throws AgiException {
        String data = channelName
                + (StringUtils.isBlank(number) ? "" : "/" + number) + sep
                + timeout;
        if (StringUtils.isNotBlank(extraOptions)) {
            data = data + sep + extraOptions;
        }
        expect(getChannel().exec("Dial", data)).andReturn(0);
    }

    @Then("set P-Charging-Vector")
    public void setPChargingVector() throws AgiException {
        String icid = getIcid() == null ? "[-0-9abcdef]+" : getIcid();
        String chargingVectorPattern = "^P-Charging-Vector: icid-value=" + icid
                + "; icid-generated-at=" + TEST_NODE_NAME + "$";
        expect(
                getChannel().exec(eq("SipAddHeader"),
                        matches(chargingVectorPattern))).andReturn(0);
    }

    @Then("dial non SIP channel $channel with number $number, timeout $timeout and separator $sep")
    public void dialNonSipChannel(String channelName, String number,
            int timeout, String sep) throws AgiException {
        expect(
                getChannel().exec(
                        "Dial",
                        channelName
                                + (StringUtils.isBlank(number) ? "" : "/"
                                        + number) + sep + timeout))
                .andReturn(0);
    }

    @Then("set ISUP to $isup")
    public void setCustomWoomera(String rdnis) throws AgiException {
        expect(getChannel().exec("Set", "_WOOMERA_CUSTOM=" + rdnis)).andReturn(
                0);
    }

    //TODO 1.9.1 ne doit etre utilise que par Isdn
    @Deprecated
    @Given("deprecated calling presentation $val")
    public void deprecatedCallingPres(String val) throws AgiException {
        expect(getChannel().getVariable("CALLERID(num-pres)")).andStubReturn(val);
    }

    //TODO 1.9.1 remove
    @Deprecated
    @Given("calling presentation $val")
    public void callingPres(String val) throws AgiException {
        expect(getChannel().getVariable("CALLERID(num-pres)")).andStubReturn(val);
    }

    @When("full variable $name contains $value")
    public void expectGetFullVariable(String name, String value)
            throws AgiException {
        expect(getChannel().getFullVariable("${" + name + "}")).andStubReturn(
                normalize(value));
    }

    public void expectGetVariable(String name, String value)
            throws AgiException {
        expect(getChannel().getVariable(name)).andStubReturn(
                normalize(value));
    }

    private String normalize(String value) {
        if ("<null>".equals(value)) {
            value = null;
        }
        return value;
    }

    @Given("header $name: $value")
    public void expectGetSipHeader(String name, String value)
            throws AgiException {
        expectGetVariable("SIP_HEADER(" + name + ")", value);
    }

    @Given("account code $account_code")
    public void expectGetAccountCode(String accountCode) {
        accountCode = normalize(accountCode);
        expect(getRequest().getAccountCode()).andStubReturn(accountCode);
    }

    @Then("add header $name: $value")
    public void setHeader(String name, String value) throws AgiException {
        expect(getChannel().exec("SipAddHeader", name + ": " + value))
                .andReturn(0);
    }

    @Given("release cause $cause")
    public void releaseCause(String cause) throws AgiException {
        expect(getChannel().getVariable("HANGUPCAUSE")).andReturn(cause);
    }

    @Given("answered time $answeredtime")
    public void expectAnsweredTime(String answeredTime) throws AgiException {
        expect(getChannel().getVariable("ANSWEREDTIME"))
                .andReturn(answeredTime);
    }

    @Given("dial status $status")
    public void expectDialStatus(String status) throws AgiException {
        expect(getChannel().getVariable("DIALSTATUS")).andReturn(
                normalize(status));
    }

    @Then("hangup with cause $cause")
    public void expectHangup(String cause) throws AgiException {
      expect(getChannel().exec("Hangup", cause)).andReturn(0);
    }

    @Then("cdr $icid/$carrier_code - $cin/$cia/$cin/$ceid/$cp/$ciN -- $cen/$cea/$cen")
    public void incompleteDataCdrWithIdentityAndPresentation(String icid, String carrierCode,
            String callingNetwork, String callingAccountCode, String callingNumber,
            String callerEffectiveIdentityNumber, String presentation, String callingName,
            String calledNetwork, String calledAccountCode, String calledNumber) {
        checkCdr(false, icid, "<any>", "<any>", callingNetwork,
            callingAccountCode, callingNumber, callerEffectiveIdentityNumber,
            presentation, callingName, carrierCode, calledNetwork,
            calledAccountCode, calledNumber, carrierCode);
    }

    @Then("cdr $icid/$carrier_code - $cin/$cia/$cin/$ceid/$ciN -- $cen/$cea/$ceN")
    public void incompleteDataCdrWithIdentity(String icid, String carrierCode,
            String callingNetwork, String callingAccountCode,
            String callingNumber, String callerEffectiveIdentityNumber,
            String callingName, String calledNetwork, String calledAccountCode,
            String calledNumber) {
        checkCdr(false, icid, "<any>", "<any>", callingNetwork,
            callingAccountCode, callingNumber, callerEffectiveIdentityNumber,
            "<any>", callingName, carrierCode, calledNetwork,
            calledAccountCode, calledNumber, carrierCode);
    }

    @Then("cdr $icid/$carrier_code - $cin/$cia/$cin/$ciN -- $cen/$cea/$ceN")
    public void incompleteDataCdr(String icid, String carrierCode,
            String callingNetwork, String callingAccountCode,
            String callingNumber, String callingName, String calledNetwork,
            String calledAccountCode, String calledNumber) {
        checkCdr(false, icid, "<any>", "<any>", callingNetwork,
            callingAccountCode, callingNumber, "<any>", "<any>",
            callingName, carrierCode, calledNetwork, calledAccountCode,
            calledNumber, carrierCode);
    }

    @Then("complete cdr $icid/$ec/$bd/$carrier_code - $cin/$cia/$cin/$ceid/$cp/$ciN -- $cen/$cea/$cen")
    public void completeDataCdrWithIdentityAndPresentation(String icid, String endCause,
            String billableDuration, String carrierCode, String callingNetwork,
            String callingAccountCode, String callingNumber, String callerEffectiveIdentityNumber,
            String presentation, String callingName, String calledNetwork,
            String calledAccountCode, String calledNumber) {
        checkCdr(true, icid, endCause, billableDuration, callingNetwork, callingAccountCode,
            callingNumber, callerEffectiveIdentityNumber, presentation, callingName,
            carrierCode, calledNetwork, calledAccountCode, calledNumber, carrierCode);
    }
    
    @Then("complete cdr $icid/$ec/$bd/$carrier_code - $cin/$cia/$cin/$ceid/$ciN -- $cen/$cea/$cen")
    public void completeDataCdrWithIdentity(String icid, String endCause,
            String billableDuration, String carrierCode, String callingNetwork,
            String callingAccountCode, String callingNumber, String callerEffectiveIdentityNumber,
            String callingName, String calledNetwork, String calledAccountCode, String calledNumber) {
        checkCdr(true, icid, endCause, billableDuration, callingNetwork,
            callingAccountCode, callingNumber, callerEffectiveIdentityNumber,
            "<any>", callingName, carrierCode, calledNetwork, calledAccountCode,
            calledNumber, carrierCode);
    }

    @Then("complete cdr $icid/$ec/$bd/$carrier_code - $cin/$cia/$cin/$ciN -- $cen/$cea/$cen")
    public void completeDataCdr(String icid, String endCause, String billableDuration,
        String carrierCode, String callingNetwork, String callingAccountCode,
        String callingNumber, String callingName, String calledNetwork,
        String calledAccountCode, String calledNumber) {
        checkCdr(true, icid, endCause, billableDuration, callingNetwork,
            callingAccountCode, callingNumber, "<any>", "<any>", callingName,
            carrierCode, calledNetwork, calledAccountCode, calledNumber, carrierCode);
    }

    @Then("complete cdr $icid/$ec/$bd - $cin/$cia/$cin/$ceid/$priv/$ciN/$cicc -- $cen/$cea/$cen/$cecc")
    public void completeDataCdrBothCarriersAndIdentityAndPresentation(String icid, String endCause,
        String billableDuration, String callingNetwork, String callingAccountCode,
        String callingNumber, String callerEffectiveIdentityNumber, String presentation,
        String callingName, String callingCarrierCode, String calledNetwork,
        String calledAccountCode, String calledNumber, String calledCarrierCode) {
        checkCdr(true, endCause, billableDuration, icid, callingNetwork, callingAccountCode,
            callingNumber, callerEffectiveIdentityNumber, presentation, callingName,
            callingCarrierCode, calledNetwork, calledAccountCode, calledNumber, calledCarrierCode);
    }

    @Then("complete cdr $icid/$ec/$bd - $cin/$cia/$cid/$ceid/$ciN/$cicc -- $cen/$cea/$cen/$cecc")
    public void completeDataCdrBothCarriersAndIdentity(String icid, String endCause,
        String billableDuration, String callingNetwork, String callingAccountCode,
        String callingNumber, String callerEffectiveIdentityNumber, String callingName,
            String callingCarrierCode, String calledNetwork, String calledAccountCode,
            String calledNumber, String calledCarrierCode) {
        checkCdr(true, icid, endCause, billableDuration, callingNetwork, 
            callingAccountCode, callingNumber, callerEffectiveIdentityNumber,
            "<any>", callingName, callingCarrierCode, calledNetwork, 
            calledAccountCode, calledNumber, calledCarrierCode);
    }

    @Then("complete cdr $icid/$ec/$bd - $cin/$cia/$cid/$ciN/$cicc -- $cen/$cea/$cen/$cecc")
    public void completeDataCdrBothCarriers(String icid, String endCause,
        String billableDuration, String callingNetwork, String callingAccountCode,
        String callingNumber, String callingName, String callingCarrierCode,
        String calledNetwork, String calledAccountCode, String calledNumber,
        String calledCarrierCode) {
        checkCdr(true, icid, endCause, billableDuration, callingNetwork,
            callingAccountCode, callingNumber, "<any>" , "<any>",
            callingName, callingCarrierCode, calledNetwork, calledAccountCode,
            calledNumber, calledCarrierCode);
    }

    @Then("complete cdr $icid $endCause $billableDuration")
    public void checkCdrEndCause(String icid, String endCause,
        String billableDuration) {
      CdrArgumentMatcher matcher = new CdrArgumentMatcher(true, icid,
          endCause, billableDuration);
        EasyMock.reportMatcher(matcher);
        getTemplate().sendCdrMessage(null);
    }

    public void checkCdr(final boolean expectComplete, String icid,
        String endCause, String billableDuration, String callingNetwork,
        String callingAccountCode, String callingNumber,
        String callingEffectiveIdentityNumber, String presentation,
            String callingName, String callingCarrierCode,
            String calledNetwork, String calledAccountCode,
            String calledNumber, String calledCarrierCode) {
        CdrArgumentMatcher matcher = new CdrArgumentMatcher(expectComplete,
            icid, endCause, billableDuration, normalizeNet(callingNetwork),
            callingAccountCode, callingNumber, callingEffectiveIdentityNumber,
            presentation, callingName, callingCarrierCode,
            normalizeNet(calledNetwork), calledAccountCode, calledNumber,
            null, calledCarrierCode);
        EasyMock.reportMatcher(matcher);
        getTemplate().sendCdrMessage(null);
    }

    private String normalizeNet(final String net) {
        if ("i".equals(net)) {
            return VnoConstants.INTERNAL_NETWORK;
        } else if ("e".equals(net)) {
            return VnoConstants.EXTERNAL_NETWORK;
        }
        return net;
    }

    @Then("stream file $file with escape digit $escape_digit and press $digit")
    public void streamFile(String file, String escapeDigit, String digit)
        throws AgiException {
        expect(getChannel().streamFile(file, escapeDigit)).andReturn(digit.charAt(0));
    }

    @Then("say date time $date with escape digit $escape_digit and press $digit")
    public void sayDate(String date, String escapeDigit, String digit)
        throws AgiException, ParseException {
        SimpleDateFormat ISO8601DATEFORMAT = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", Locale.FRANCE);
        expect(getChannel().sayDateTime(ISO8601DATEFORMAT.parse(date.replaceAll(":00$", "00"))
                    .getTime()/1000L, escapeDigit, "dBY")) .andReturn(digit.charAt(0));
    }

    @Then("say alpha $alpha with escape digit $escape_digit and press $digit")
    public void sayAlpha(String alpha, String escapeDigit, String digit)
        throws AgiException {
        expect(getChannel().sayAlpha(alpha, escapeDigit)).andReturn(digit.charAt(0));
    }

    @Then("say rio $rio with escape digit $escape_digit and press $digit")
    public void sayRio(String rio, String escapeDigit, String digit)
        throws AgiException {
        sayAlpha(rio, escapeDigit, digit);
    }

    @Then("wait for digit $escape_digit $time miliseconds and press $digit")
    public void waitForDigit(String escapeDigit, String time, String digit)
        throws AgiException {
        expect(getChannel().waitForDigit(Integer.parseInt(time))).andReturn(digit.charAt(0));
    }

    @Then("send sms with msisdn: $msisdn, rio: $rio, date: $date")
    public void sendSMS(String msisdn, String rio, String date)
        throws TimeoutException {
        SviRioQueryResponse sviRioResponse;
        if (!StringUtils.isBlank(normalize(date))) {
            sviRioResponse = SviRioQueryResponse.newBuilder()
                .setMsisdn(msisdn).setRio(rio).setDate(date).build();
        } else {
            sviRioResponse = SviRioQueryResponse.newBuilder()
                .setMsisdn(msisdn).setRio(rio).build();
        }
        SmsServerAck smsResponse = SmsServerAck.newBuilder().setStatus(200).build();
        expect(getSiTemplate().sendRioBySms(sviRioResponse)).andReturn(smsResponse);
    }

    @Then("answer")
    public void answer() throws AgiException {
        getChannel().answer();
    }

    @Then("noop $text")
    public void noop(String text) throws AgiException {
        expect(getChannel().exec("NoOp", "  " + text)).andReturn(0);
    }

    @Then("rand $rand with $gw_number gateways")
    public void rand(Integer randomIndex, Integer gwNumber) {
        expect(getRandom().nextInt(gwNumber)).andReturn(randomIndex);
    }

    @Then("done")
    public void done() throws AgiException {
        getMockCtrl().replay();
        getAgi().service(getRequest(), getChannel());
        getMockCtrl().verify();
    }

    public AbstractSigalAgi getAgi() {
        return agi;
    }

    public AgiChannel getChannel() {
        return channel;
    }

    public AgiRequest getRequest() {
        return request;
    }

    public SigalAgentTemplate getTemplate() {
        return template;
    }

    public SiAgentTemplate getSiTemplate() {
        return siTemplate;
    }

    public void setAgi(AbstractSigalAgi agi) {
        this.agi = agi;
    }

    public void setChannel(AgiChannel channel) {
        this.channel = channel;
    }

    public void setRequest(AgiRequest request) {
        this.request = request;
    }

    public void setTemplate(SigalAgentTemplate template) {
        this.template = template;
    }

    public void setSiTemplate(SiAgentTemplate siTemplate) {
        this.siTemplate = siTemplate;
    }

    protected Map<String, String> parseOptions(String data) {
        HashMap<String, String> map = new HashMap<String, String>();

        String[] pairs = data.split(", *");
        for (int i = 0; i < pairs.length; i++) {
            String[] parts = pairs[i].split(" *: *");

            map.put(parts[0], parts[1]);
        }
        return map;
    }
}
