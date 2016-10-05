package com.dwolla.j2ee

import javax.servlet.http.HttpServletResponse

import org.specs2.mock.Mockito
import org.specs2.mutable.Specification
import org.specs2.specification.Scope

class RedirectServletTest extends Specification with Mockito {

  trait Setup extends Scope {
    val classToTest = new RedirectServlet
    val httpServletResponse = mock[HttpServletResponse]
  }

  "RedirectServlet" should {
    "set response code 301" in new Setup {
      classToTest.service(null, httpServletResponse)

      there was one(httpServletResponse).setStatus(301)
    }

    "set redirection location" in new Setup {
      classToTest.service(null, httpServletResponse)

      there was one(httpServletResponse).addHeader("Location", "/crowd/")
    }
  }

}
