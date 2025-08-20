
export default function App(){
  return (
    <main className="max-w-4xl mx-auto p-6">
      <div className="card mb-4">
        <h1 className="text-2xl font-bold">USDTg • TetherGround</h1>
        <p className="opacity-80 mt-2">Official website: docs, policies, downloads.</p>
      </div>
      <div className="card">
        <h2 className="text-xl font-semibold mb-2">Company Documents</h2>
        <ul className="list-disc pl-6 text-sm">
          <li><a href="/docs/company/registration.pdf" target="_blank">Registration certificate</a></li>
          <li><a href="/docs/company/operating-agreement.pdf" target="_blank">Operating Agreement</a></li>
          <li><a href="/docs/company/privacy.pdf" target="_blank">Privacy Policy</a></li>
        </ul>
      </div>
    </main>
  )
}
