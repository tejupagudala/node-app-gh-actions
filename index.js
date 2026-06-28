const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({ message: "Hello from the end-to-end GitHub Actions pipeline!! Hurrayyy I amde it" });
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
