# --- OTel setup: must happen BEFORE importing starter ---
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor

provider = TracerProvider()
provider.add_span_processor(
    SimpleSpanProcessor(ConsoleSpanExporter())
)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("llm-zoomcamp")

# --- Now import the RAG pieces ---
from rag_helper import RAGBase
from starter import rag  # starter's pre-built RAGBase instance (has .index, .llm_client, etc.)


class RAGTraced(RAGBase):

    def search(self, query, num_results=5):
        with tracer.start_as_current_span("search") as span:
            results = super().search(query, num_results=num_results)
            span.set_attribute("num_results", len(results))
            return results

    def llm(self, prompt):
        with tracer.start_as_current_span("llm") as span:
            response = super().llm(prompt)
            usage = response.usage
            span.set_attribute("input_tokens", usage.input_tokens)
            span.set_attribute("output_tokens", usage.output_tokens)
            return response

    def rag(self, query):
        with tracer.start_as_current_span("rag") as span:
            return super().rag(query)


# Build the traced version using the same collaborators as the starter's rag object
rag_traced = RAGTraced(
    index=rag.index,
    llm_client=rag.llm_client,
    model=rag.model,
)

query = "How does the agentic loop keep calling the model until it stops?"
answer = rag_traced.rag(query)

print("\n--- ANSWER ---")
print(answer)