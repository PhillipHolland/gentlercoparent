export default function Home() {
  return (
    <div style={{ padding: '2rem', fontFamily: 'Arial, sans-serif', textAlign: 'center' }}>
      <h1>Gentler Coparent Enhanced API</h1>
      <p>RAG-enabled API for co-parenting guidance</p>
      <div style={{ marginTop: '2rem' }}>
        <p><strong>Endpoint:</strong> <code>/api/enhanced-chat</code></p>
        <p><strong>Methods:</strong> POST (chat), PUT (knowledge upload), GET (status)</p>
        <p style={{ marginTop: '1rem', padding: '1rem', backgroundColor: '#f5f5f5', borderRadius: '8px' }}>
          <strong>Status:</strong> ✅ Active and ready for requests
        </p>
      </div>
    </div>
  )
}