function saveCredentials(username, password) {
    // Check if running in browser and if credential management is available
    if (typeof window !== 'undefined' && window.navigator && 
        navigator.credentials && navigator.credentials.preventSilentAccess) {
      // Create credential object
      const cred = new PasswordCredential({
        id: username,
        password: password,
        name: username,
      });
      
      // Store the credentials
      navigator.credentials.store(cred)
        .then(() => console.log("Credentials saved successfully"))
        .catch(err => console.error("Error saving credentials:", err));
    }
  }
  
  function saveAuthToken(token) {
    // Save token in localStorage
    if (typeof window !== 'undefined' && window.localStorage) {
      localStorage.setItem('auth_token', token);
      console.log("Auth token saved to localStorage");
    }
  }
  
  function getAuthToken() {
    // Get token from localStorage
    if (typeof window !== 'undefined' && window.localStorage) {
      return localStorage.getItem('auth_token');
    }
    return null;
  }
  
  function displayPdf(data, filename) {
    // Create a Blob from the PDF data
    const blob = new Blob([Uint8Array.from(data)], { type: 'application/pdf' });
    
    // Create a URL for the Blob
    const url = URL.createObjectURL(blob);
    
    // Open the PDF in a new tab
    window.open(url, '_blank');
    
    // Clean up the URL after a delay
    setTimeout(() => URL.revokeObjectURL(url), 30000);
  }