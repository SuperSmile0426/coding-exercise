import "jsr:@supabase/functions-js/edge-runtime.d.ts"

console.log("Hello from Functions!")

export const handler = async (req: Request) => {
  const url = new URL(req.url);
  const operation = url.searchParams.get("operation") || "reverse";
  
  let result;
  
  switch (operation) {
    case "reverse":
      const text = url.searchParams.get("text") || "";
      result = { reversed: text.split("").reverse().join("") };
      break;
      
    case "random":
      const min = parseInt(url.searchParams.get("min") || "0");
      const max = parseInt(url.searchParams.get("max") || "100");
      result = { random: Math.floor(Math.random() * (max - min + 1)) + min };
      break;
      
    case "timestamp":
      const format = url.searchParams.get("format") || "iso";
      const date = new Date();
      if (format === "unix") {
        result = { timestamp: Math.floor(date.getTime() / 1000) };
      } else {
        result = { timestamp: date.toISOString() };
      }
      break;
      
    default:
      return new Response(JSON.stringify({ error: "Invalid operation" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
  }

  return new Response(JSON.stringify(result), {
    headers: { "Content-Type": "application/json" },
  });
};

// Start the server
Deno.serve(handler);