package com.initsys.sigal.agent.db;

import java.util.HashMap;
import java.util.Map;

import javax.sql.DataSource;

import org.apache.commons.lang.time.StopWatch;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.jdbc.core.simple.SimpleJdbcTemplate;

import com.google.protobuf.Message;
import com.initsys.sigal.protocol.Sigal.LidbUpdateRequest;
import com.initsys.sigal.protocol.Sigal.ResponseStatus;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;

/**
 * TODO: refactorer avec la partie SCP.
 * 
 * @author dom
 * 
 */
public class AgentDbSigalService {

	private SimpleJdbcTemplate template;
	private DataSource dataSource;

	public DataSource getDataSource() {
		return dataSource;
	}

	protected SimpleJdbcTemplate getTemplate() {
		return template;
	}

	private void setTemplate(SimpleJdbcTemplate template) {
		this.template = template;
	}

	public void setDataSource(DataSource source) {
		this.dataSource = source;
		setTemplate(new SimpleJdbcTemplate(source));
	}

	/** logger */
	private static final Logger log = LoggerFactory.getLogger(AgentDbSigalService.class);

	public Message onMessage(Message query) {
		Message response = null;
		StopWatch watch = new StopWatch();

		watch.start();
		try {
			LidbUpdateRequest request = (LidbUpdateRequest) query;
			// insert into sip_buddies
			// (name, type, secret, host, dtmfmode, `call-limit`, musiconhold,
			// mailbox, qualify, context, nat, callerid, defaultuser)
			// values("test_realtime", "friends", "toto", "dynamic", "rfc2833",
			// 100, "default", "100@test-client,1234", "yes", "test-client-op",
			// "yes", "RTtester Foo","default");
			Map<String, Object> parameters = new HashMap<String, Object>();

			parameters.put("name", request.getAccountCode());

			parameters.put("type", "friend");
			parameters.put("secret", request.getPassword());

			// TODO: finishi

			new SimpleJdbcInsert(getDataSource()).withTableName("sip_buddies")
					.usingColumns("name", "type", "secret", "host", "dtmfmode",
							"musiconhold", "qualify", "context", "nat",
							"callerid", "defaultuser").execute(parameters);

			return response;
		} finally {
			watch.stop();
			if (log.isDebugEnabled()) {
				log.debug(String.format("Queried in %3dms: \n  %s\n  %s", watch
						.getTime(), query.toString().replaceAll("\n", "\n  "),
						response == null ? "<null>" : response.toString()
								.replaceAll("\n", "\n  ")));
			}
		}
	}

	/**
	 * Builds a status from the type and message argument.
	 * 
	 * @param code
	 *            Status code to return.
	 * @param msg
	 *            Ignored if null.
	 * @return
	 */
	protected ResponseStatus buildStatus(ResponseStatusCode code, String msg) {
		ResponseStatus.Builder builder = ResponseStatus.newBuilder().setCode(
				code);
		if (msg != null) {
			builder.setMessage(msg);
		}

		return builder.build();
	}

}
