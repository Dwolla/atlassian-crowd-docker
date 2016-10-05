package com.dwolla.j2ee;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class RedirectServlet extends HttpServlet {
    @Override protected void service(final HttpServletRequest req, final HttpServletResponse resp) {
        resp.setStatus(301);
        resp.addHeader("Location", "/crowd/");
    }
}
