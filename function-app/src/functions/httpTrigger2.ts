import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

export async function httpTrigger2(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`Http function processed request for url "${request.url}"`);

    const name = request.query.get('name') || await request.text() || 'human';

    return { body: `This is another test, ${name}!` };
};

app.http('httpTrigger2', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: httpTrigger2
});