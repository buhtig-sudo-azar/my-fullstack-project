
import React from 'react';

function App() {
  const checkBackend = async () => {
    try {
      const response = await fetch('https://psychic-engine-4jq5wp695vvwc7v99-3001.app.github.dev/api/status');;
      const data = await response.json();
      alert(`Бэкенд ответил: ${data.status}`);
    } catch (error) {
      alert('Не удалось подключиться к бэкенду!');
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h1>System Dashboard</h1>
      <button onClick={checkBackend}>
        Проверить связь с бэкендом
      </button>
    </div>
  );
}

export default App;