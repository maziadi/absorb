package com.initsys.sigal.service.as.dao;

import java.util.List;

import com.initsys.sigal.protocol.Sigal.NpdbQueryRequest;
import com.initsys.sigal.service.as.NpdbEntry;

public interface NpdbDao {

    public abstract List<NpdbEntry> query(NpdbQueryRequest request);

}