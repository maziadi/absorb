package com.initsys.sigal.agent.agi;

import static org.easymock.EasyMock.createMock;
import static org.easymock.EasyMock.createStrictMock;
import static org.easymock.EasyMock.eq;
import static org.easymock.EasyMock.expect;
import static org.easymock.EasyMock.matches;
import static org.easymock.EasyMock.replay;
import static org.easymock.EasyMock.reset;
import static org.easymock.EasyMock.verify;

import java.util.concurrent.TimeoutException;

import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;
import org.asteriskjava.fastagi.AgiRequest;
import org.easymock.EasyMock;
import org.junit.After;

import com.initsys.sigal.agent.AgentStatisticsImpl;
import com.initsys.sigal.agent.SigalAgentTemplate;
import com.initsys.sigal.protocol.Sigal.Cdr;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.NpdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ResponseStatus;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;

public abstract class SigalAgiAbstractTest<A extends AbstractSigalAgi> {

    private static final String TEST_NODE_NAME = "testNode";

    public static final ResponseStatus OK_STATUS = ResponseStatus.newBuilder()
            .setCode(ResponseStatusCode.OK).build();

    public static final ResponseStatus NOT_FOUND_STATUS = ResponseStatus
            .newBuilder().setCode(ResponseStatusCode.NOT_FOUND).build();

    private A agi;

    private AgiChannel channel;

    private AgiRequest request;

    private SigalAgentTemplate template;

    public A getAgi() {
        return agi;
    }

    public AgiChannel getChannel() {
        return channel;
    }

    public AgiRequest getRequest() {
        return request;
    }

    public void setAgi(A agi) {
        this.agi = agi;
    }

    public void setChannel(AgiChannel channel) {
        this.channel = channel;
    }

    public void setRequest(AgiRequest request) {
        this.request = request;
    }

    /**
     * Hack to instanciate the AGI and prepare the mocks.
     */

    @SuppressWarnings("unchecked")
    public void setUp() throws Exception {
        String parameterClassName = (getClass().getGenericSuperclass()
                .toString().replaceFirst("^[^<]*<([^>]+)>.*$", "$1"));

        setAgi((A) Class.forName(parameterClassName).newInstance());

        setRequest(createMock(AgiRequest.class));
        setChannel(createStrictMock(AgiChannel.class));
        setTemplate(createStrictMock(SigalAgentTemplate.class));
        getAgi().setTemplate(getTemplate());
        getAgi().setNodeName(TEST_NODE_NAME);
        getAgi().setStatistics(new AgentStatisticsImpl());
    }

    protected void replayAll() {
        replay(getRequest());
        replay(getChannel());
        replay(getTemplate());

    }

    protected void stageRequest(String extension) throws AgiException {
        expect(getRequest().getCallerIdName()).andStubReturn("Foo");
        expect(getRequest().getExtension()).andStubReturn(extension);
        expect(getRequest().getChannel()).andStubReturn("SIP/xyzetodo");
        expect(getRequest().getDnid()).andStubReturn("TODO");
        expect(getRequest().getAccountCode()).andStubReturn("TODO");
        expect(getRequest().getRdnis()).andStubReturn("");
        expect(getRequest().getCallerIdNumber()).andStubReturn("+33000000001");
        expect(getChannel().getVariable("ANSWEREDTIME")).andStubReturn("1234");
        expect(
                getChannel().getVariable(
                        "SIP_HEADER(X-RedirectingNumber)"))
                .andStubReturn("");

        expect(getChannel().getVariable("SIP_HEADER(X-CarrierCode)"))
                .andStubReturn("initsys.default");
        stageSipDomainQuery("0990000000002.mrf-10.sip.openvno.net");
        expect(getChannel().getVariable("SIP_HEADER(P-Charging-Vector)"))
                .andStubReturn("icid-123234134123412341");

        getTemplate().sendCdrMessage((Cdr) EasyMock.anyObject());
        EasyMock.expectLastCall().asStub();
    }

    protected void stageXRedirectTo(String redirectingNumber)
            throws AgiException {
        expect(
                getChannel().getVariable(
                        "SIP_HEADER(X-RedirectingNumber)")).andReturn(
                redirectingNumber).anyTimes();
    }

    protected void stageCallerIdNum(String callerIdNum) {
        expect(getRequest().getCallerIdNumber()).andReturn(callerIdNum)
                .anyTimes();
    }

    protected void stageAccountCode(String accountCode) {
        expect(getRequest().getAccountCode()).andReturn(accountCode).anyTimes();
    }

    protected void stageIsup(String rdnis) throws AgiException {
        //expect(getChannel().getFullVariable("${WOOMERA_CUSTOM}")).andReturn(
        //        rdnis).anyTimes();
    }

    public SigalAgentTemplate getTemplate() {
        return template;
    }

    public void setTemplate(SigalAgentTemplate template) {
        this.template = template;
    }

    protected void verifyTemplateAndChannel() {
        verify(getTemplate());
        verify(getChannel());
    }

    protected void expectDial(String channelName, String number,
            String options, String sep, String extraOptions)
            throws AgiException {
        expect(
                getChannel().exec(
                        "Dial",
                        channelName
                                + "/"
                                + number
                                + sep
                                + options
                                + (extraOptions == null ? "" : sep
                                        + extraOptions))).andReturn(0);
    }

    protected void expectChargingVector(String icidValue) throws AgiException {
        String icid = icidValue == null ? "[0-9-abcdef]+" : icidValue;
        String pattern = "^P-Charging-Vector: icid-value=" + icid
                + "; icid-generated-at=" + TEST_NODE_NAME + "$";
        expect(getChannel().exec(eq("SipAddHeader"), matches(pattern)))
                .andReturn(0);
    }

    protected void expectAddEmergencyHeader() throws AgiException {
        expect(getChannel().exec("SipAddHeader", "X-CarrierCode: emergency"))
                .andReturn(0);
    }

    protected void expectPortedQuery(String number, String prefix)
            throws TimeoutException {
        NpdbQueryResponse.Builder response = NpdbQueryResponse.newBuilder()
                .setVersion(1).setNumber(number);

        if (prefix != null) {
            response.setPrefix(prefix);
        }

        expect(getTemplate().queryPorted(number)).andReturn(response.build());
    }

    protected void expectExchangeQuery(String accountCode, String outboundNumberingPlan,
            String inboundNumberingPlan, String carrierCode)
            throws TimeoutException {
        ExdbQueryResponse.Builder response = ExdbQueryResponse.newBuilder()
                .setVersion(1).setAccountCode(accountCode)
                .setStatus(OK_STATUS);

        if (outboundNumberingPlan != null) {
            response.setOutboundNumberingPlan(outboundNumberingPlan);
        }
        if (inboundNumberingPlan != null) {
            response.setInboundNumberingPlan(inboundNumberingPlan);
        }
        if (carrierCode != null) {
            response.setCarrierCode(carrierCode);
        }
        expect(getTemplate().queryIntercoByAccountCode(accountCode)).andReturn(response.build());
    }

    protected void expectLineInfoQuery(String number, String redirectTo,
            String accountCode, String outboundNumberingPlan,
            String inboundNumberingPlan, String carrierCode, String inseeCode)
            throws TimeoutException {
        LidbQueryResponse.Builder response = LidbQueryResponse.newBuilder()
                .setVersion(1).setNumber(number).setAccountCode(accountCode)
                .setStatus(OK_STATUS);

        response.setTrunk(true);

        if (redirectTo != null) {
            response.setRedirectTo(redirectTo);
        }
        if (outboundNumberingPlan != null) {
            response.setOutboundNumberingPlan(outboundNumberingPlan);
        }
        if (inboundNumberingPlan != null) {
            response.setInboundNumberingPlan(inboundNumberingPlan);
        }
        if (carrierCode != null) {
            response.setCarrierCode(carrierCode);
        }
        if (inseeCode != null) {
            response.setInseeCode(inseeCode);
        }
        expectLineInfoQuery(number, response.build());
    }

    protected void expectLineInfoByAccountCodeQuery(String accountCode,
            String inseeCode, String subscriberNumber,
            String outboundNumberingPlan, String inboundNumberingPlan,
            String carrierCode) throws TimeoutException {
        LidbQueryResponse.Builder response = LidbQueryResponse.newBuilder();

        response.setVersion(1);
        response.setOutboundNumberingPlan(outboundNumberingPlan);
        response.setInboundNumberingPlan(inboundNumberingPlan);
        response.setAccountCode(accountCode);
        // response.setRedirectTo(null);
        response.setInseeCode(inseeCode);
        response.setSubscriberNumber(subscriberNumber);
        response.setStatus(OK_STATUS);
        if (carrierCode != null) {
            response.setCarrierCode(carrierCode);
        }
        expect(getTemplate().queryLineInfoByAccountCode(accountCode))
                .andReturn(response.build());
    }

    protected void expectLineInfoQueryNotFound(String number)
            throws TimeoutException {
        LidbQueryResponse response = LidbQueryResponse.newBuilder().setVersion(
                1).setNumber(number).setStatus(NOT_FOUND_STATUS).build();

        expectLineInfoQuery(number, response);
    }

    private void expectLineInfoQuery(String number, LidbQueryResponse response)
            throws TimeoutException {
        expect(getTemplate().queryLineInfoByNumber(number)).andReturn(response);
    }

    protected void executeScenario() throws AgiException {
        replayAll();

        getAgi().service(getRequest(), getChannel());

        verifyTemplateAndChannel();
    }

    protected void expectCaller(String num, String name, String pres,
            boolean FT, String newNum) throws AgiException {
        if (!FT) {
            expectGetCallerIdNum(num);
        } else {
            stageCallerIdNum(num);
        }
        expectSetCallerIdNum(newNum == null ? num : newNum);
        if (name != null) {
            expectSetCallerIdName(name);
        }
        /* expectSetCallerPres(pres); */
    }

    protected void expectGetCallerIdNumPres(String pres) throws AgiException {
      /* TODO 1.9.1 supprimer */
      /*   expect(getChannel().getVariable("CALLERID(num-pres)")).andReturn(pres); */
        expect(getChannel().getVariable("SIP_HEADER(Privacy: id)")).andReturn(pres);
    }

    protected void expectSetCallerPres(String pres) throws AgiException {
      /* TODO 1.9.1 supprimer */
      /*   expect(getChannel().exec("Set", "CALLERID(num-pres)=" + pres)).andReturn(0); */
          expect(getChannel().exec("SipAddHeader", "Privacy: id")).andReturn(0);
    }

    protected void expectGetCallerIdNum(String num) throws AgiException {
        expect(getChannel().getFullVariable("${CALLERID(num)}")).andReturn(num);
    }

    protected void expectSetCallerIdNum(String num) throws AgiException {
        expect(getChannel().exec("Set", "CALLERID(num)=" + num)).andReturn(0);
    }

    protected void expectSetCarrierCode(String name) throws AgiException {
        expect(getChannel().exec("SipAddHeader", "X-CarrierCode: " + name))
                .andReturn(0);
    }

    protected void expectSetAccountCode(String name) throws AgiException {
        expect(getChannel().exec("SipAddHeader", "X-AccountCode: " + name))
                .andReturn(0);
    }

    protected void expectSetCallerIdName(String name) throws AgiException {
        expect(getChannel().exec("Set", "CALLERID(name)=" + name)).andReturn(0);
    }

    protected void resetAllMocks() {
        reset(getRequest());
        reset(getChannel());
        reset(getTemplate());
    }

    protected void expectDialStatus(int answeredTime, String status)
            throws AgiException {
        expect(getChannel().getVariable("DIALSTATUS")).andReturn(status);
        // TODO: handle HANGUP CAUSE
        expect(getChannel().getVariable("HANGUPCAUSE")).andReturn("TODO");

        expect(getChannel().getVariable("ANSWEREDTIME")).andReturn(
                String.valueOf(answeredTime));

    }

    public void stageSipDomainQuery(String sipDomain) throws AgiException {
        expect(getChannel().getFullVariable("${SIPDOMAIN}")).andStubReturn(
                sipDomain);
    }

    @After
    public void tearDown() {
        if (getAgi() != null) {
            System.out.println("STATS: " + getAgi().getStatistics());
        }
    }

}
