/*

Cleaning Data in SQL


*/

SELECT *
FROM PortfolioProject..NashvilleHousing
----------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- We create a new column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
FROM PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data

SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL 
ORDER BY ParcelID

-- After inspecting the data we can see that for every ParcelID that's duplicated the addresses repit themselves as well
-- We can do a self-join to get all duplicated ParcelID with a specific UniqueID which means that we won't get repeated rows
SELECT x.ParcelID, x.PropertyAddress, y.ParcelID, y.PropertyAddress
FROM PortfolioProject..NashvilleHousing x
JOIN PortfolioProject..NashvilleHousing y
ON x.ParcelID = y.ParcelID
AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress IS NULL 

-- And now we can populate the PropertyAddress where they're null and update our table
SELECT x.ParcelID, x.PropertyAddress, y.ParcelID, y.PropertyAddress, ISNULL(x.PropertyAddress, y.PropertyAddress)
FROM PortfolioProject..NashvilleHousing x
JOIN PortfolioProject..NashvilleHousing y
ON x.ParcelID = y.ParcelID
AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress IS NULL 

UPDATE x
SET PropertyAddress = ISNULL(x.PropertyAddress, y.PropertyAddress)
FROM PortfolioProject..NashvilleHousing x
JOIN PortfolioProject..NashvilleHousing y
ON x.ParcelID = y.ParcelID
AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress IS NULL 

----------------------------------------------------------------------------------------------------------------------

-- Breaking Address into individual columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

-- We can see that for every address there's a comma acting as a delimiter, so we can break that down
-- Using SUBSTRING:
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

-- We create two new columns and update 
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- The new columns will be at the end 
SELECT *
FROM PortfolioProject..NashvilleHousing

-- And now we'll repeat the process for the OwnerAddress but this time we'll use PARSENAME, but we have to keep in mind that it only works with '.' and not with ','
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing

-- We add the new columns and update
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in 'Sold as Vacant' field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' 
     WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END 
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' 
     WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END 

----------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 LegalReference
				 ORDER BY 
				    UniqueID) AS row_num
FROM PortfolioProject..NashvilleHousing)

DELETE
FROM RowNumCTE 
WHERE row_num > 1


----------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns
-- Note: this is just for practicing purposes. You should never delete information from your raw data

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate

SELECT *
FROM PortfolioProject..NashvilleHousing
