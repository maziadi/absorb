package com.initsys.sigal.service.as.dao;

import java.util.List;

import com.initsys.sigal.protocol.Sigal.ExdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.ExdbUpdateRequest;
import com.initsys.sigal.service.as.ExdbEntry;

public interface ExdbDao {

    public int updateDatabase(final ExdbUpdateRequest request);

    public List<ExdbEntry> queryByAccountCode(ExdbQueryRequest exdbQuery);
}