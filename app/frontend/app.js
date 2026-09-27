// ===============================
// API CONFIGURATION
// ===============================

const API_URL = "/api";

let employees = [];

let editingEmployeeId = null;


// ===============================
// PAGE LOAD
// ===============================

document.addEventListener("DOMContentLoaded", function () {

    loadEmployees();

});


// ===============================
// LOAD EMPLOYEES FROM FASTAPI
// ===============================

async function loadEmployees() {

    try {

        const response =
            await fetch(`${API_URL}/employees`);

        if (!response.ok) {
            throw new Error("Failed to load employees");
        }

        employees = await response.json();

        displayEmployees();

        updateStatistics();

    }
    catch (error) {

        console.error("Error loading employees:", error);

        alert("Unable to connect to the backend.");

    }

}


// ===============================
// DISPLAY EMPLOYEES
// ===============================

function displayEmployees(employeeList = employees) {

    const table =
        document.getElementById("employeeTable");

    table.innerHTML = "";


    if (employeeList.length === 0) {

        table.innerHTML = `
            <tr>
                <td colspan="5" class="empty-message">
                    No employees found
                </td>
            </tr>
        `;

        return;
    }


    employeeList.forEach(employee => {

        const initials =
            getInitials(employee.name);

        const row =
            document.createElement("tr");


        row.innerHTML = `

            <td>

                <div class="employee-info">

                    <div class="employee-avatar">
                        ${initials}
                    </div>

                    <div>

                        <strong>
                            ${employee.name}
                        </strong>

                        <small>
                            ID: EMP${String(employee.id).padStart(3, "0")}
                        </small>

                    </div>

                </div>

            </td>


            <td>
                ${employee.role}
            </td>


            <td>

                <span class="department engineering">
                    ${employee.department}
                </span>

            </td>


            <td>
                ${employee.email}
            </td>


            <td>

                <button
                    class="action-btn edit"
                    onclick="editEmployee(${employee.id})"
                >
                    Edit
                </button>


                <button
                    class="action-btn delete"
                    onclick="deleteEmployee(${employee.id})"
                >
                    Delete
                </button>

            </td>

        `;


        table.appendChild(row);

    });

}


// ===============================
// GET INITIALS
// ===============================

function getInitials(name) {

    const words =
        name.trim().split(" ");


    if (words.length === 1) {

        return words[0]
            .substring(0, 2)
            .toUpperCase();

    }


    return (
        words[0][0] +
        words[words.length - 1][0]
    ).toUpperCase();

}


// ===============================
// OPEN MODAL
// ===============================

function openModal() {

    editingEmployeeId = null;

    document
        .getElementById("employeeModal")
        .classList.add("show");

}


// ===============================
// CLOSE MODAL
// ===============================

function closeModal() {

    document
        .getElementById("employeeModal")
        .classList.remove("show");


    document
        .getElementById("employeeForm")
        .reset();


    editingEmployeeId = null;

}


// ===============================
// ADD / UPDATE EMPLOYEE
// ===============================

document
    .getElementById("employeeForm")
    .addEventListener("submit", async function (event) {

        event.preventDefault();


        const name =
            document
                .getElementById("name")
                .value
                .trim();


        const email =
            document
                .getElementById("email")
                .value
                .trim();


        const role =
            document
                .getElementById("role")
                .value
                .trim();


        const department =
            document
                .getElementById("department")
                .value;


        const employeeData = {

            name: name,

            email: email,

            role: role,

            department: department

        };


        try {

            let response;


            // ===============================
            // UPDATE EXISTING EMPLOYEE
            // ===============================

            if (editingEmployeeId !== null) {

                response =
                    await fetch(
                        `${API_URL}/employees/${editingEmployeeId}`,
                        {
                            method: "PUT",

                            headers: {
                                "Content-Type": "application/json"
                            },

                            body: JSON.stringify(employeeData)
                        }
                    );

            }


            // ===============================
            // CREATE NEW EMPLOYEE
            // ===============================

            else {

                response =
                    await fetch(
                        `${API_URL}/api/employees`,
                        {
                            method: "POST",

                            headers: {
                                "Content-Type": "application/json"
                            },

                            body: JSON.stringify(employeeData)
                        }
                    );

            }


            const result =
                await response.json();


            if (!response.ok) {

                throw new Error(
                    result.detail || "Operation failed"
                );

            }


            closeModal();

            await loadEmployees();


            if (editingEmployeeId !== null) {

                alert(
                    "Employee updated successfully!"
                );

            }
            else {

                alert(
                    "Employee added successfully!"
                );

            }

        }
        catch (error) {

            console.error(error);

            alert(error.message);

        }

    });


// ===============================
// DELETE EMPLOYEE
// ===============================

async function deleteEmployee(id) {

    const employee =
        employees.find(
            emp => emp.id === id
        );


    if (!employee) {
        return;
    }


    const confirmed =
        confirm(
            `Delete ${employee.name}?`
        );


    if (!confirmed) {
        return;
    }


    try {

        const response =
            await fetch(
                `${API_URL}/api/employees/${id}`,
                {
                    method: "DELETE"
                }
            );


        const result =
            await response.json();


        if (!response.ok) {

            throw new Error(
                result.detail || "Delete failed"
            );

        }


        await loadEmployees();


        alert(
            "Employee deleted successfully!"
        );

    }
    catch (error) {

        console.error(error);

        alert(error.message);

    }

}


// ===============================
// EDIT EMPLOYEE
// ===============================

function editEmployee(id) {

    const employee =
        employees.find(
            emp => emp.id === id
        );


    if (!employee) {
        return;
    }


    editingEmployeeId = id;


    document.getElementById("name").value =
        employee.name;


    document.getElementById("email").value =
        employee.email;


    document.getElementById("role").value =
        employee.role;


    document.getElementById("department").value =
        employee.department;


    document
        .getElementById("employeeModal")
        .classList.add("show");

}


// ===============================
// SEARCH
// ===============================

function searchEmployees() {

    const searchValue =
        document
            .getElementById("searchInput")
            .value
            .toLowerCase();


    const filtered =
        employees.filter(employee =>

            employee.name
                .toLowerCase()
                .includes(searchValue)

            ||

            employee.email
                .toLowerCase()
                .includes(searchValue)

            ||

            employee.role
                .toLowerCase()
                .includes(searchValue)

            ||

            employee.department
                .toLowerCase()
                .includes(searchValue)

        );


    displayEmployees(filtered);

}


// ===============================
// STATISTICS
// ===============================

function updateStatistics() {

    document
        .getElementById("totalEmployees")
        .textContent =
        employees.length;


    document
        .getElementById("activeEmployees")
        .textContent =
        employees.length;


    const departments =
        new Set(
            employees.map(
                employee => employee.department
            )
        );


    document
        .getElementById("totalDepartments")
        .textContent =
        departments.size;


    document
        .getElementById("newEmployees")
        .textContent =
        employees.length;

}