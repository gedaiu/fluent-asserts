module http.request;

import vibe.inet.url;
import vibe.http.router;
import vibe.http.form;
import vibe.data.json;

import vibe.stream.memory;

import std.conv, std.string, std.array;
import std.algorithm, std.conv;
import std.stdio;
import std.exception;

import bdd.string;

RequestRouter request(URLRouter router)
{
	return new RequestRouter(router);
}

final class RequestRouter
{
	private
	{
		alias ExpectedCallback = void delegate(Response res);
		ExpectedCallback[] expected;
		URLRouter router;
		HTTPServerRequest preparedRequest;

		string[string] headers;

		string responseBody;
	}

	this(URLRouter router)
	{
		this.router = router;
	}


	RequestRouter send(string[string] data) {
		auto dst = appender!string;

		dst.writeFormData(data);
		header("content-type", "application/x-www-form-urlencoded");

		return send(dst.data);
	}

	RequestRouter send(T)(T data)
	{
		static if (is(T == string))
		{
			preparedRequest.bodyReader = new MemoryStream(cast(ubyte[]) data);
			return this;
		}
		else static if (is(T == Json))
		{
			preparedRequest.json = data;
			return send(data.to!string);
		}
		else
		{
			return send(data.serializeToJson());
		}
	}

	RequestRouter header(string name, string value)
	{
		if(preparedRequest is null) {
			headers[name] = value;
		} else {
			preparedRequest.headers[name] = value;
		}
		return this;
	}

	RequestRouter post(string path)
	{
		return request!(HTTPMethod.POST)(URL("http://localhost" ~ path));
	}

	RequestRouter patch(string path)
	{
		return request!(HTTPMethod.PATCH)(URL("http://localhost" ~ path));
	}

	RequestRouter put(string path)
	{
		return request!(HTTPMethod.PUT)(URL("http://localhost" ~ path));
	}

	RequestRouter delete_(string path)
	{
		return request!(HTTPMethod.DELETE)(URL("http://localhost" ~ path));
	}

	RequestRouter get(string path)
	{
		return request!(HTTPMethod.GET)(URL("http://localhost" ~ path));
	}

	RequestRouter request(HTTPMethod method)(URL url)
	{
		preparedRequest = createTestHTTPServerRequest(url, method);
		preparedRequest.host = "localhost";

		foreach(name, value; headers) {
			preparedRequest.headers[name] = value;
		}

		return this;
	}

	RequestRouter expectHeaderExist(string name, const string file = __FILE__, const size_t line = __LINE__)
	{
		void localExpectHeaderExist(Response res) {
			enforce(name in res.headers, "Response header `" ~ name ~ "` is missing.", file, line);
		}

		expected ~= &localExpectHeaderExist;

		return this;
	}

	RequestRouter expectHeader(string name, string value, const string file = __FILE__, const size_t line = __LINE__)
	{
		expectHeaderExist(name, file, line);

		void localExpectedHeader(Response res) {
			enforce(res.headers[name] == value,
				"Response header `" ~ name ~ "` has an unexpected value. Expected `"
				~ value ~ "` != `" ~ res.headers[name].to!string ~ "`", file, line);
		}

		expected ~= &localExpectedHeader;

		return this;
	}

	RequestRouter expectHeaderContains(string name, string value, const string file = __FILE__, const size_t line = __LINE__)
	{
		expectHeaderExist(name, file, line);

		void expectHeaderContains(Response res) {
			enforce(res.headers[name].indexOf(value) != -1,
				"Response header `" ~ name ~ "` has an unexpected value. Expected `"
				~ value ~ "` not found in `" ~ res.headers[name].to!string ~ "`", file, line);
		}

		expected ~= &expectHeaderContains;

		return this;
	}

	RequestRouter expectStatusCode(int code, const string file = __FILE__, const size_t line = __LINE__)
	{
		void localExpectStatusCode(Response res) {
			if(code != 404 && res.statusCode == 404) {
				writeln("\n\nIs your route defined here?");
				router.getAllRoutes.map!(a => a.method.to!string ~ " " ~ a.pattern).each!writeln;
			}

			enforce(code == res.statusCode,
					"Expected status code `" ~ code.to!string
					~ "` not found. Got `" ~ res.statusCode.to!string ~ "` instead", file, line);
		}

		expected ~= &localExpectStatusCode;


		return this;
	}

	private void performExpected(Response res)
	{
		foreach(func; expected) {
			func(res);
		}
	}

	void end() {
		end((Response response) => { });
	}

	void end(T)(T callback)
	{
		import vibe.stream.operations : readAllUTF8;
		import vibe.inet.webform;

		auto data = new ubyte[5000];

		MemoryStream stream = new MemoryStream(data);
		HTTPServerResponse res = createTestHTTPServerResponse(stream);
		res.statusCode = 404;

		auto ptype = "Content-Type" in preparedRequest.headers;

		if (ptype) {
			parseFormData(preparedRequest.form, preparedRequest.files, *ptype, preparedRequest.bodyReader, 5000);
		}

		parseURLEncodedForm(preparedRequest.queryString, preparedRequest.query);

		router.handleRequest(preparedRequest, res);

		string responseString = (cast(string) data).toStringz.to!string;
		checkResponse(responseString);

		auto response = new Response(responseString);

		callback(response)();

		performExpected(response);
	}

	void checkResponse(ref string data) {
		if(data.length > 0) {
			return;
		}

		data = "HTTP/1.1 404 No Content\r\n\r\n";
	}
}

class Response
{
	string bodyString;

	private
	{
		Json _bodyJson;
		string responseLine;
		string data;
	}

	string[string] headers;
	int statusCode;

	this(string data)
	{
		this.data = data;

		auto bodyIndex = data.indexOf("\r\n\r\n");

		assert(bodyIndex != -1, "Invalid response data: \n" ~ data ~ "\n\n");

		auto headers = data[0 .. bodyIndex].split("\r\n").array;

		responseLine = headers[0];
		statusCode = headers[0].split(" ")[1].to!int;

		foreach (i; 1 .. headers.length)
		{
			auto header = headers[i].split(": ");
			this.headers[header[0]] = header[1];
		}

		bodyString = data[bodyIndex + 4 .. $];
	}

	@property Json bodyJson()
	{
		if (_bodyJson.type == Json.Type.undefined)
		{
			try {
				_bodyJson = bodyString.parseJson;
			} catch(Exception e) {
				writeln("`" ~ bodyString ~ "` is not a json string");
			}
		}

		return _bodyJson;
	}

	override
	string toString() {
		return data;
	}
}
