package com.initsys.sigal.service.as;

import java.sql.Date;
import java.sql.Time;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.jdbc.CannotGetJdbcConnectionException;

import com.google.protobuf.Message;
import com.initsys.sigal.protocol.SigalProtocolHelper;
import com.initsys.sigal.protocol.Sigal.EmdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.EmdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;
import com.initsys.sigal.service.as.dao.EmdbDao;

public class DbBackedEmdbAsServiceImpl extends AbstractSigalAsService {

  /** logger */
  private static final Logger log = LoggerFactory
    .getLogger(DbBackedEmdbAsServiceImpl.class);

  private EmdbDao dao;

  public EmdbDao getDao() {
    return dao;
  }

  public void setDao(EmdbDao dao) {
    this.dao = dao;
  }

  @Override
  public Message handleQuery(Message request) {
    EmdbQueryRequest emdbRequest = (EmdbQueryRequest) request;
    EmdbQueryResponse.Builder response = EmdbQueryResponse.newBuilder();
    // TODO: pas portable en dehors de la france
    Calendar calendar = Calendar.getInstance(TimeZone
        .getTimeZone("Europe/Paris"), Locale.FRANCE);
    Time time = new Time(calendar.getTime().getTime());
    Date currentDay = new Date(calendar.getTime().getTime());
    int dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK) - 1; // TODO: hack
    calendar.add(Calendar.DAY_OF_WEEK, -1);
    Date dayBefore = new Date(calendar.getTime().getTime());

    log.info(String.format(
          "Querying emergency translations for %s in %s at %s (%d)",
          emdbRequest.getNumber(), emdbRequest.getInseeCode(), time,
          dayOfWeek));

    response.setVersion(1);
    response.setNumber(emdbRequest.getNumber());
    response.setInseeCode(emdbRequest.getInseeCode());

    try {
      List<EmdbEntry> list = getDao().query(emdbRequest, time, currentDay, dayOfWeek,
          dayBefore);

      if (list.isEmpty()) {
        response.setStatus(SigalProtocolHelper.buildStatus(ResponseStatusCode.NOT_FOUND, null));
      } else {
        processResult(response, list);
        response.setStatus(SigalProtocolHelper.buildStatus(ResponseStatusCode.OK, null));
      }
      sleep(20000);
      return response.build();
    } catch (final CannotGetJdbcConnectionException e) {
      response.setStatus(SigalProtocolHelper.buildStatus(
            ResponseStatusCode.ERROR, "DB Connection failure"));
      return response.build();
    }
  }

  void processResult(EmdbQueryResponse.Builder response, List<EmdbEntry> list) {
    EmdbEntry[] entries = list.toArray(new EmdbEntry[list.size()]);

    for (int i = 0; i < entries.length; i++) {
      EmdbEntry entry = entries[i];
      if (entry.getIndex() == null) {
        // should not happen but still continue
        continue;
      }
      if (i < (entries.length - 1)
          && entry.getIndex().equals(entries[i + 1].getIndex())) {
        i++; // go to next
        if (entry.getDayOfWeek() == null) {
          // use next
          entry = entries[i];
        }
          }
      response.addTranslation(entry.getTranslatedNumber());
    }
  }
}