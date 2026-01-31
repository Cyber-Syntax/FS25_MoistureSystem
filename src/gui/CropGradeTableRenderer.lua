---
-- Crop Grade Table Renderer
--

CropGradeTableRenderer = {}
CropGradeTableRenderer_mt = Class(CropGradeTableRenderer)

function CropGradeTableRenderer.new()
    local self = {}
    setmetatable(self, CropGradeTableRenderer_mt)
    self.data = {}
    return self
end

function CropGradeTableRenderer:setData(data)
    self.data = data
end

function CropGradeTableRenderer:getNumberOfSections()
    return 1
end

function CropGradeTableRenderer:getNumberOfItemsInSection(list, section)
    return #self.data
end

function CropGradeTableRenderer:getTitleForSectionHeader(list, section)
    return ""
end

function CropGradeTableRenderer:populateCellForItemInSection(list, section, index, cell)
    local cropData = self.data[index]

    cell:getAttribute("cropName"):setText(cropData.name)
    cell:getAttribute("gradeA"):setText(cropData.gradeA)
    cell:getAttribute("gradeB"):setText(cropData.gradeB)
    cell:getAttribute("gradeC"):setText(cropData.gradeC)
    cell:getAttribute("gradeD"):setText(cropData.gradeD)
end

function CropGradeTableRenderer:onListSelectionChanged(list, section, index)
    -- No action needed on selection
end
