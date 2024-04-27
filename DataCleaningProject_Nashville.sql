-- Data cleaning project

-- Let´s take a look to the table and verify the data to clean, modify and/or standarize

SELECT *
FROM DataCleaning_Nashville..NashvilleHousing


-- Data format standarization: from DateTime to Date

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE 	NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, saledate)


-- Property Address: check the NULLs. Can any column be referenced? Yes, ParcelID. Let´s to complete the PropertyAddress

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning_Nashville..NashvilleHousing a
JOIN DataCleaning_Nashville..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning_Nashville..NashvilleHousing a
JOIN DataCleaning_Nashville..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


-- PropertyAddress. Break into individual columns: Address, City

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS address,
--CHARINDEX(',', PropertyAddress) --con charindex cuento cuantos lugares hasta la coma, como no la quiero, por eso pongo en la funcion de arriba -1
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS city
FROM DataCleaning_Nashville..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertyAddressSplited NVARCHAR(255);

UPDATE 	NashvilleHousing
SET PropertyAddressSplited = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD CityProperty NVARCHAR(255);

UPDATE 	NashvilleHousing
SET CityProperty = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- OwnerAddress. Break into individual columns: Address, City, State

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),--parsename is useful for periods. Replace comas for periods (punto como simbolo en ingles)
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), --si pongo 1 toma hasta la primera coma pero desde atras
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM DataCleaning_Nashville..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddres NVARCHAR(255);

UPDATE 	NashvilleHousing
SET OwnerSplitAddres = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE 	NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE 	NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Unify Sold As Vacant column: "Y" to "Yes" and "N" to "No"

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM DataCleaning_Nashville..NashvilleHousing


UPDATE DataCleaning_Nashville..NashvilleHousing 	
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END

-- Removing duplicates

WITH row_num AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM DataCleaning_Nashville..NashvilleHousing
)
/*SELECT *
FROM row_num
WHERE row_num >1 -- si no hubiera hecho cte no podria hacer este where. es para saber cuantas lineas repiten los valores importantes mencionados en el cte

--1RO lo hago para consultar, luego cambio el select * por delete y luego select otra vez para verificar la si se borro
DELETE
FROM row_num
WHERE row_num > 1 */
SELECT *
FROM row_num
WHERE row_num >1

-- Delete unused columns

SELECT*
FROM DataCleaning_Nashville..NashvilleHousing

ALTER TABLE DataCleaning_Nashville..NashvilleHousing
DROP COLUMN Owneraddress, TaxDistrict, PropertyAddress, SaleDate
